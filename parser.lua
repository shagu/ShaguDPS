-- load public variables into local
local parser = ShaguDPS.parser

local playerClasses = ShaguDPS.playerClasses
local view_dmg_all = ShaguDPS.view_dmg_all
local view_dps_all = ShaguDPS.view_dps_all
local dmg_table = ShaguDPS.dmg_table
local config = ShaguDPS.config
local round = ShaguDPS.round

-- populate all valid player units
local validUnits = { ["player"] = true }
for i=1,4 do validUnits["party" .. i] = true end
for i=1,40 do validUnits["raid" .. i] = true end

-- populate all valid player pets
local validPets = { ["pet"] = true }
for i=1,4 do validPets["partypet" .. i] = true end
for i=1,40 do validPets["raidpet" .. i] = true end

parser.ScanName = function(self, name)
  -- check if name matches a real player
  for unit, _ in pairs(validUnits) do
    if UnitExists(unit) and UnitName(unit) == name then
      if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        playerClasses[name] = class
        return true
      end
    end
  end

  -- check if name matches a player pet
  for unit, _ in pairs(validPets) do
    if UnitExists(unit) and UnitName(unit) == name then
      -- parse and set pet owners
      if strsub(unit,0,3) == "pet" then
        playerClasses[name] = UnitName("player")
      elseif strsub(unit,0,8) == "partypet" then
        playerClasses[name] = UnitName("party" .. strsub(unit,9))
      elseif strsub(unit,0,7) == "raidpet" then
        playerClasses[name] = UnitName("raid" .. strsub(unit,8))
      end

      return true
    end
  end

  -- assign class other if tracking of all units is set
  if config.track_all_units == 1 then
    playerClasses[name] = playerClasses[name] or "__other__"
    return true
  else
    return false
  end
end

parser.AddData = function(self, source, attack, target, damage, school, force)
  -- Debug:
  -- DEFAULT_CHAT_FRAME:AddMessage(source .. " (" .. attack .. ") -> " .. target .. ": " .. damage .. " (" .. (school or "nil") .. ")")

  -- write dmg_table table
  if not dmg_table[source] and ( parser:ScanName(source) or force ) then
    dmg_table[source] = {}
  end

  -- write pet damage into owners data if enabled
  if config.merge_pets == 1 and
    playerClasses[source] ~= "__other__" and
    (dmg_table[playerClasses[source]] or parser:ScanName(playerClasses[source]))
  then
    attack = "Pet: " .. source
    source = playerClasses[source]

    if not dmg_table[source] then
      dmg_table[source] = {}
    end
  end

  if dmg_table[source] then
    dmg_table[source][attack] = (dmg_table[source][attack] or 0) + tonumber(damage)
    dmg_table[source]["_sum"] = (dmg_table[source]["_sum"] or 0) + tonumber(damage)

    dmg_table[source]["_ctime"] = dmg_table[source]["_ctime"] or 0
    dmg_table[source]["_tick"] = dmg_table[source]["_tick"] or GetTime()

    if dmg_table[source]["_tick"] + 5 < GetTime() then
      dmg_table[source]["_tick"] = GetTime()
      dmg_table[source]["_ctime"] = dmg_table[source]["_ctime"] + 5
    else
      dmg_table[source]["_ctime"] = dmg_table[source]["_ctime"] + (GetTime() - dmg_table[source]["_tick"])
      dmg_table[source]["_tick"] = GetTime()
    end
  else
    return
  end

  if dmg_table[source] then
    view_dmg_all[source] = (view_dmg_all[source] or 0) + tonumber(damage)
    view_dps_all[source] = round(view_dmg_all[source] / math.max(dmg_table[source]["_ctime"], 1), 1)
  end

  for id, callback in pairs(parser.callbacks.refresh) do
    callback()
  end
end

parser.callbacks = {
  ["refresh"] = {}
}
