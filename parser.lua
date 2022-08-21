-- load public variables into local
local parser = ShaguDPS.parser

local data = ShaguDPS.data
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
        data["classes"][name] = class
        return "PLAYER"
      end
    end
  end

  -- check if name matches a player pet
  for unit, _ in pairs(validPets) do
    if UnitExists(unit) and UnitName(unit) == name then
      -- parse and set pet owners
      if strsub(unit,0,3) == "pet" then
        data["classes"][name] = UnitName("player")
      elseif strsub(unit,0,8) == "partypet" then
        data["classes"][name] = UnitName("party" .. strsub(unit,9))
      elseif strsub(unit,0,7) == "raidpet" then
        data["classes"][name] = UnitName("raid" .. strsub(unit,8))
      end

      return "PET"
    end
  end

  -- assign class other if tracking of all units is set
  if config.track_all_units == 1 then
    data["classes"][name] = data["classes"][name] or "__other__"
    return "OTHER"
  else
    return nil
  end
end

parser.AddData = function(self, source, attack, target, damage, school, force)
  -- abort on invalid input
  if type(source) ~= "string" then return end

  -- trim leading and trailing spaces
  source = trim(source)

  -- write dmg_table table
  if not data["damage"][source] then
    local type = parser:ScanName(source) or force
    if type == "PET" then
      -- create owner table if not yet existing
      local owner = data["classes"][source]
      if not data["damage"][owner] and parser:ScanName(owner) then
        data["damage"][owner] = {}
      end
    elseif not type then
      -- invalid or disabled unit type
      return
    end

    -- create base damage table
    data["damage"][source] = {}
  end

  -- write pet damage into owners data if enabled
  if config.merge_pets == 1 and                 -- merge pets?
    data["classes"][source] ~= "__other__" and  -- valid unit?
    data["damage"][data["classes"][source]]     -- has owner?
  then
    attack = "Pet: " .. source
    source = data["classes"][source]

    if not data["damage"][source] then
      data["damage"][source] = {}
    end
  end

  if data["damage"][source] then
    data["damage"][source][attack] = (data["damage"][source][attack] or 0) + tonumber(damage)
    data["damage"][source]["_sum"] = (data["damage"][source]["_sum"] or 0) + tonumber(damage)

    data["damage"][source]["_ctime"] = data["damage"][source]["_ctime"] or 1
    data["damage"][source]["_tick"] = data["damage"][source]["_tick"] or GetTime()

    if data["damage"][source]["_tick"] + 5 < GetTime() then
      data["damage"][source]["_tick"] = GetTime()
      data["damage"][source]["_ctime"] = data["damage"][source]["_ctime"] + 5
    else
      data["damage"][source]["_ctime"] = data["damage"][source]["_ctime"] + (GetTime() - data["damage"][source]["_tick"])
      data["damage"][source]["_tick"] = GetTime()
    end
  else
    return
  end

  for id, callback in pairs(parser.callbacks.refresh) do
    callback()
  end
end

parser.callbacks = {
  ["refresh"] = {}
}
