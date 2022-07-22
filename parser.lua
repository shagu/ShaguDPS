-- load public variables into local
local parser = ShaguDPS.parser
local playerClasses = ShaguDPS.playerClasses
local view_dmg_all = ShaguDPS.view_dmg_all
local view_dps_all = ShaguDPS.view_dps_all
local dmg_table = ShaguDPS.dmg_table
local config = ShaguDPS.config
local round = ShaguDPS.round

--healing extension variables
local parser2 = ShaguDPS.parser2
local view_heal_all = ShaguDPS.view_heal_all
local heal_table = ShaguDPS.heal_table

-- populate all valid player units
local validUnits = { ["player"] = true }
for i=1,4 do validUnits["party" .. i] = true end
for i=1,40 do validUnits["raid" .. i] = true end

-- populate all valid player pets
local validPets = { ["pet"] = true }
for i=1,4 do validPets["partypet" .. i] = true end
for i=1,40 do validPets["raidpet" .. i] = true end

-- trim leading and trailing spaces
local function trim(str)
  return gsub(str, "^%s*(.-)%s*$", "%1")
end

parser.ScanName = function(self, name)
  -- check if name matches a real player
  for unit, _ in pairs(validUnits) do
    if UnitExists(unit) and UnitName(unit) == name then
      if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        playerClasses[name] = class
        return "PLAYER"
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

      return "PET"
    end
  end

  -- assign class other if tracking of all units is set
  if config.track_all_units == 1 then
    playerClasses[name] = playerClasses[name] or "__other__"
    return "OTHER"
  else
    return nil
  end
end

--parse damage
parser.AddData = function(self, source, attack, target, damage, school, force)
  -- abort on invalid input
  if type(source) ~= "string" then return end

  -- trim leading and trailing spaces
  source = trim(source)

  -- write dmg_table table
  if not dmg_table[source] then
    local type = parser:ScanName(source) or force
    if type == "PET" then
      -- create owner table if not yet existing
      local owner = playerClasses[source]
      if not dmg_table[owner] and parser:ScanName(owner) then
        dmg_table[owner] = {}
      end
    elseif not type then
      -- invalid or disabled unit type
      return
    end

    -- create base damage table
    dmg_table[source] = {}
  end

  -- write pet damage into owners data if enabled
  if config.merge_pets == 1 and               -- merge pets?
    playerClasses[source] ~= "__other__" and  -- valid unit?
    dmg_table[playerClasses[source]]          -- has owner?
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

--parse heals
parser2.AddData = function(self, source, attack, target, damage, school, force)
  -- abort on invalid input
  if type(source) ~= "string" then return end

  -- trim leading and trailing spaces
  source = trim(source)

  -- write heal_table table
  if not heal_table[source] then
    local type = parser:ScanName(source) or force
    if not type then
      -- invalid or disabled unit type
      return
    end
    -- create base heal table
    heal_table[source] = {}
  end
  
  --find ID for target of heal so we can get missing health for effective healing calc.
  local effectiveAmount = damage
  local unitID = MikCEH.GetUnitIDFromName(target);
  if not unitID then
	if UnitName("target") == target then
		unitID = "target";
	end
  end

 -- Make sure it's a valid unit id. then calc. effective healing
  if (unitID) then
	effectiveAmount = min(UnitHealthMax(unitID) - UnitHealth(unitID), damage)
  end
	
  if heal_table[source] then
    --since heal_table[source][attack] ist a table itself with heal and effective heal it needs to be created first
    if heal_table[source][attack] == nil then heal_table[source][attack] = {} end
	if heal_table[source]["_sum"] == nil then heal_table[source]["_sum"] = {} end
    
	heal_table[source][attack] = {(heal_table[source][attack][1] or 0) + tonumber(damage), (heal_table[source][attack][2] or 0) + tonumber(effectiveAmount)}
    heal_table[source]["_sum"] = {(heal_table[source]["_sum"][1] or 0) + tonumber(damage), (heal_table[source]["_sum"][2] or 0) + tonumber(effectiveAmount)}
  else
    return
  end

  if heal_table[source] then
    if view_heal_all[source] == nil then view_heal_all[source] = {} end
    view_heal_all[source] = {(view_heal_all[source][1] or 0) + tonumber(damage), (view_heal_all[source][2] or 0) + tonumber(effectiveAmount)}
  end

  for id, callback in pairs(parser2.callbacks.refresh) do
    callback()
  end
end

parser.callbacks = {
  ["refresh"] = {}
}
parser2.callbacks = {
  ["refresh"] = {}
}
