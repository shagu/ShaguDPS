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

-- find unitstr by name
local unit_cache = {}
local function UnitByName(name)
  -- skip all scans if cache is still valid
  if unit_cache[name] and UnitName(unit_cache[name]) == name then
    return unit_cache[name]
  end

  -- scan players for current name
  for unit in pairs(validUnits) do
    if UnitName(unit) == name then
      unit_cache[name] = unit
      return unit
    end
  end

  -- scan pets for current name
  for unit in pairs(validPets) do
    if UnitName(unit) == name then
      unit_cache[name] = unit
      return unit
    end
  end
end

-- trim leading and trailing spaces
local function trim(str)
  return gsub(str, "^%s*(.-)%s*$", "%1")
end

local function combat()
  -- check if in combat
  if UnitAffectingCombat("player") or UnitAffectingCombat("pet") then
    return true
  end

  local raid = GetNumRaidMembers()
  local group = GetNumPartyMembers()

  if raid >= 1 then
    for i = 1, raid do
      -- check if any raid member is infight
      if UnitAffectingCombat("raid"..i) or UnitAffectingCombat("raidpet"..i) then return true end
    end
  else
    for i = 1, group do
      -- check if any group member is infight
      if UnitAffectingCombat("party"..i) or UnitAffectingCombat("partypet"..i) then return true end
    end
  end

  return nil
end

local start_next_segment = nil
parser.combat = CreateFrame("Frame", "ShaguDPSCombatState", UIParent)
parser.combat:RegisterEvent("PLAYER_REGEN_DISABLED")
parser.combat:RegisterEvent("PLAYER_REGEN_ENABLED")

-- scan and trigger combat state changes
parser.combat.UpdateState = function(self)
  local state = combat() == true and "COMBAT" or "NO_COMBAT"
  if not self.oldstate or self.oldstate ~= state then
    self.oldstate = state

    if state == "NO_COMBAT" then
      start_next_segment = true
    end
  end
end

-- check when player leaves/enters combat
parser.combat:SetScript("OnEvent", function()
  this:UpdateState()
end)

-- check each second
parser.combat:SetScript("OnUpdate", function()
  if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  this:UpdateState()
end)

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

parser.AddData = function(self, source, action, target, value, school, datatype)
  -- abort on invalid input
  if type(source) ~= "string" then return end

  -- trim leading and trailing spaces
  source = trim(source)

  -- clear "current" on fight start
  if start_next_segment and data["classes"][source] and data["classes"][source] ~= "__other__" then
    data["damage"][1] = {}
    data["heal"][1] = {}

    start_next_segment = nil
  end

  -- calculate effective value (heal)
  local effective = 0
  if datatype == "heal" then
    local unitstr = UnitByName(target)

    if unitstr then
      -- calculate the effective healing of the current data
      effective = math.min(UnitHealthMax(unitstr) - UnitHealth(unitstr), value)
    end
  end

  -- write both (overall and current segment)
  for segment = 0, 1 do
    local entry = data[datatype][segment]

    -- detect source and write initial table
    if not entry[source] then
      local type = parser:ScanName(source)
      if type == "PET" then
        -- create owner table if not yet existing
        local owner = data["classes"][source]
        if not entry[owner] and parser:ScanName(owner) then
          entry[owner] = { ["_sum"] = 0, ["_ctime"] = 1 }
        end
      elseif not type then
        -- invalid or disabled unit type
        break
      end

      -- create base damage table
      entry[source] = { ["_sum"] = 0, ["_ctime"] = 1 }
    end

    -- write pet damage into owners data if enabled
    local action, source = action, source
    if config.merge_pets == 1 and                 -- merge pets?
      data["classes"][source] ~= "__other__" and  -- valid unit?
      entry[data["classes"][source]]              -- has owner?
    then
      -- remove pet data
      entry[source] = nil

      action = "Pet: " .. source
      source = data["classes"][source]

      -- write data into owner
      if not entry[source] then
        entry[source] = { ["_sum"] = 0, ["_ctime"] = 1 }
      end
    end

    if entry[source] then
      -- write overall value and per spell
      entry[source][action] = (entry[source][action] or 0) + tonumber(value)
      entry[source]["_sum"] = (entry[source]["_sum"] or 0) + tonumber(value)

      if datatype == "heal" then
        -- write effective healing sumary
        entry[source]["_esum"] = (entry[source]["_esum"] or 0) + tonumber(effective)

        -- write effective healing per spell
        entry[source]["_effective"] = entry[source]["_effective"] or {}
        entry[source]["_effective"][action] = (entry[source]["_effective"][action] or 0) + tonumber(effective)
      end

      entry[source]["_ctime"] = entry[source]["_ctime"] or 1
      entry[source]["_tick"] = entry[source]["_tick"] or GetTime()

      if entry[source]["_tick"] + 5 < GetTime() then
        entry[source]["_tick"] = GetTime()
        entry[source]["_ctime"] = entry[source]["_ctime"] + 5
      else
        entry[source]["_ctime"] = entry[source]["_ctime"] + (GetTime() - entry[source]["_tick"])
        entry[source]["_tick"] = GetTime()
      end
    end
  end

  for id, callback in pairs(parser.callbacks.refresh) do
    callback()
  end
end

parser.callbacks = {
  ["refresh"] = {}
}
