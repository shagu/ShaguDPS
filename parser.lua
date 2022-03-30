-- load public variables into local
local parser = ShaguDPS.parser

local playerClasses = ShaguDPS.playerClasses
local view_dmg_all = ShaguDPS.view_dmg_all
local dmg_table = ShaguDPS.dmg_table
local config = ShaguDPS.config

-- populate all valid units (unless trackall is set)
local validUnits = { ["player"] = true, ["pet"] = true }
for i=1,4 do validUnits["party" .. i] = true end
for i=1,4 do validUnits["partypet" .. i] = true end
for i=1,40 do validUnits["raid" .. i] = true end
for i=1,40 do validUnits["raidpet" .. i] = true end

local function prepare(template)
  template = gsub(template, "%(", "%%(") -- fix ( in string
  template = gsub(template, "%)", "%%)") -- fix ) in string
  template = gsub(template, "%d%$","")
  template = gsub(template, "%%s", "(.+)")
  return gsub(template, "%%d", "(%%d+)")
end

parser.ScanName = function(self, name)
  for unit, _ in pairs(validUnits) do
    if UnitExists(unit) and UnitName(unit) == name then
      if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        playerClasses[name] = class
        return true
      else
        playerClasses[name] = unit
        return true
      end
    end
  end

  if config.track_all_units == 1 then
    playerClasses[name] = playerClasses[name] or "other"
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

  if dmg_table[source] then
    dmg_table[source][attack] = (dmg_table[source][attack] or 0) + tonumber(damage)
    dmg_table[source]["_sum"] = (dmg_table[source]["_sum"] or 0) + tonumber(damage)
  else
    return
  end

  if dmg_table[source] then
    view_dmg_all[source] = (view_dmg_all[source] or 0) + tonumber(damage)
  end

  for id, callback in pairs(parser.callbacks.refresh) do
    callback(source)
  end
end

parser.callbacks = {
  ["refresh"] = {}
}

-- me source me target
local SPELLLOGSCHOOLSELFSELF = prepare(SPELLLOGSCHOOLSELFSELF) -- Your %s hits you for %d %s damage.
local SPELLLOGCRITSCHOOLSELFSELF = prepare(SPELLLOGCRITSCHOOLSELFSELF) -- Your %s crits you for %d %s damage.
local SPELLLOGSELFSELF = prepare(SPELLLOGSELFSELF) --Your %s hits you for %d.
local SPELLLOGCRITSELFSELF = prepare(SPELLLOGCRITSELFSELF) -- Your %s crits you for %d.
local PERIODICAURADAMAGESELFSELF =  prepare(PERIODICAURADAMAGESELFSELF) -- "You suffer %d %s damage from your %s.";

-- me source
local SPELLLOGSCHOOLSELFOTHER = prepare(SPELLLOGSCHOOLSELFOTHER) -- Your %s hits %s for %d %s damage.
local SPELLLOGCRITSCHOOLSELFOTHER = prepare(SPELLLOGCRITSCHOOLSELFOTHER) -- Your %s crits %s for %d %s damage.
local SPELLLOGSELFOTHER = prepare(SPELLLOGSELFOTHER) -- Your %s hits %s for %d.
local SPELLLOGCRITSELFOTHER = prepare(SPELLLOGCRITSELFOTHER) -- Your %s crits %s for %d.
local PERIODICAURADAMAGESELFOTHER = prepare(PERIODICAURADAMAGESELFOTHER) -- "%s suffers %d %s damage from your %s."; -- Rabbit suffers 3 frost damage from your Ice Nova.
local COMBATHITSELFOTHER = prepare(COMBATHITSELFOTHER) -- You hit %s for %d.
local COMBATHITCRITSELFOTHER = prepare(COMBATHITCRITSELFOTHER) -- You crit %s for %d.
local COMBATHITSCHOOLSELFOTHER = prepare(COMBATHITSCHOOLSELFOTHER) -- You hit %s for %d %s damage.
local COMBATHITCRITSCHOOLSELFOTHER = prepare(COMBATHITCRITSCHOOLSELFOTHER) -- You crit %s for %d %s damage.
local DAMAGESHIELDSELFOTHER = prepare(DAMAGESHIELDSELFOTHER) -- You reflect %d %s damage to %s.

-- me target
local SPELLLOGSCHOOLOTHERSELF = prepare(SPELLLOGSCHOOLOTHERSELF) -- %s's %s hits you for %d %s damage.
local SPELLLOGCRITSCHOOLOTHERSELF = prepare(SPELLLOGCRITSCHOOLOTHERSELF) -- %s's %s crits you for %d %s damage.
local SPELLLOGOTHERSELF = prepare(SPELLLOGOTHERSELF) -- %s's %s hits you for %d.
local SPELLLOGCRITOTHERSELF = prepare(SPELLLOGCRITOTHERSELF) -- %s's %s crits you for %d.
local PERIODICAURADAMAGEOTHERSELF = prepare(PERIODICAURADAMAGEOTHERSELF) -- "You suffer %d %s damage from %s's %s."; -- You suffer 3 frost damage from Rabbit's Ice Nova.
local COMBATHITOTHERSELF = prepare(COMBATHITOTHERSELF) -- %s hits you for %d.
local COMBATHITCRITOTHERSELF = prepare(COMBATHITCRITOTHERSELF) -- %s crits you for %d.
local COMBATHITSCHOOLOTHERSELF = prepare(COMBATHITSCHOOLOTHERSELF) -- %s hits you for %d %s damage.
local COMBATHITCRITSCHOOLOTHERSELF = prepare(COMBATHITCRITSCHOOLOTHERSELF) -- %s crits you for %d %s damage.

-- other
local SPELLLOGSCHOOLOTHEROTHER = prepare(SPELLLOGSCHOOLOTHEROTHER) -- %s's %s hits %s for %d %s damage.
local SPELLLOGCRITSCHOOLOTHEROTHER = prepare(SPELLLOGCRITSCHOOLOTHEROTHER) -- %s's %s crits %s for %d %s damage.
local SPELLLOGOTHEROTHER = prepare(SPELLLOGOTHEROTHER) -- %s's %s hits %s for %d.
local SPELLLOGCRITOTHEROTHER = prepare(SPELLLOGCRITOTHEROTHER) -- %s's %s crits %s for %d.
local PERIODICAURADAMAGEOTHEROTHER = prepare(PERIODICAURADAMAGEOTHEROTHER) -- "%s suffers %d %s damage from %s's %s."; -- Bob suffers 5 frost damage from Jeff's Ice Nova.
local COMBATHITOTHEROTHER = prepare(COMBATHITOTHEROTHER) -- %s hits %s for %d.
local COMBATHITCRITOTHEROTHER = prepare(COMBATHITCRITOTHEROTHER) -- %s crits %s for %d.
local COMBATHITSCHOOLOTHEROTHER = prepare(COMBATHITSCHOOLOTHEROTHER) -- %s hits %s for %d %s damage.
local COMBATHITCRITSCHOOLOTHEROTHER = prepare(COMBATHITCRITSCHOOLOTHEROTHER) -- %s crits %s for %d %s damage.
local DAMAGESHIELDOTHEROTHER = prepare(DAMAGESHIELDOTHEROTHER) -- %s reflects %d %s damage to %s.

local datasources = {
  --[[ me source me target ]]--
  -- Your %s hits you for %d %s damage.
  function(source, target, school, attack)
    for attack, damage, school in string.gfind(arg1, SPELLLOGSCHOOLSELFSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- Your %s crits you for %d %s damage.
  function(source, target, school, attack)
    for attack, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLSELFSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- Your %s hits you for %d.
  function(source, target, school, attack)
    for attack, damage in string.gfind(arg1, SPELLLOGSELFSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- Your %s crits you for %d.
  function(source, target, school, attack)
    for attack, damage in string.gfind(arg1, SPELLLOGCRITSELFSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- "You suffer %d %s damage from your %s.";
  function(source, target, school, attack)
    for damage, school, attack in string.gfind(arg1, PERIODICAURADAMAGESELFSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  --[[ me source ]]--
  -- Your %s hits %s for %d %s damage.
  function(source, target, school, attack)
    for attack, target, damage, school in string.gfind(arg1, SPELLLOGSCHOOLSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- Your %s crits %s for %d %s damage.
  function(source, target, school, attack)
    for attack, target, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- Your %s hits %s for %d.
  function(source, target, school, attack)
    for attack, target, damage in string.gfind(arg1, SPELLLOGSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- Your %s crits %s for %d.
  function(source, target, school, attack)
    for attack, target, damage in string.gfind(arg1, SPELLLOGCRITSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s suffers %d %s damage from your %s.";
  -- Rabbit suffers 3 frost damage from your Ice Nova.
  function(source, target, school, attack)
    for target, damage, school, attack in string.gfind(arg1, PERIODICAURADAMAGESELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- You hit %s for %d.
  function(source, target, school, attack)
    for target, damage in string.gfind(arg1, COMBATHITSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- You crit %s for %d.
  function(source, target, school, attack)
    for target, damage in string.gfind(arg1, COMBATHITCRITSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- You hit %s for %d %s damage.
  function(source, target, school, attack)
    for target, damage, school in string.gfind(arg1, COMBATHITSCHOOLSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- You crit %s for %d %s damage.
  function(source, target, school, attack)
    for target, damage, school in string.gfind(arg1, COMBATHITCRITSCHOOLSELFOTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- You reflect %d %s damage to %s.
  function(source, target, school, attack)
    for damage, school, target in string.gfind(arg1, DAMAGESHIELDSELFOTHER) do
      parser:AddData(source, "Reflection (" .. school .. ")", target, damage, school)
      return true
    end
  end,

  --[[ me target ]]--
  -- %s's %s hits you for %d %s damage.
  function(source, target, school, attack)
    for source, attack, damage, school in string.gfind(arg1, SPELLLOGSCHOOLOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s's %s crits you for %d %s damage.
  function(source, target, school, attack)
    for source, attack, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s's %s hits you for %d.
  function(source, target, school, attack)
    for source, attack, damage in string.gfind(arg1, SPELLLOGOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s's %s crits you for %d.
  function(source, target, school, attack)
    for source, attack, damage in string.gfind(arg1, SPELLLOGCRITOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- "You suffer %d %s damage from %s's %s.";
  -- You suffer 3 frost damage from Rabbit's Ice Nova.
  function(source, target, school, attack)
    for damage, school, source, attack in string.gfind(arg1, PERIODICAURADAMAGEOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s hits you for %d.
  function(source, target, school, attack)
    for source, damage in string.gfind(arg1, COMBATHITOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s crits you for %d.
  function(source, target, school, attack)
    for source, damage in string.gfind(arg1, COMBATHITCRITOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s hits you for %d %s damage.
  function(source, target, school, attack)
    for source, damage, school in string.gfind(arg1, COMBATHITSCHOOLOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s crits you for %d %s damage.
  function(source, target, school, attack)
    for source, damage, school in string.gfind(arg1, COMBATHITCRITSCHOOLOTHERSELF) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  --[[ other ]]--
  -- %s's %s hits %s for %d %s damage.
  function(source, target, school, attack)
    for source, attack, target, damage, school in string.gfind(arg1, SPELLLOGSCHOOLOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s's %s crits %s for %d %s damage.
  function(source, target, school, attack)
    for source, attack, target, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s's %s hits %s for %d.
  function(source, target, school, attack)
    for source, attack, target, damage in string.gfind(arg1, SPELLLOGOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s's %s crits %s for %d.
  function(source, target, school, attack)
    for source, attack, target, damage, school in string.gfind(arg1, SPELLLOGCRITOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- "%s suffers %d %s damage from %s's %s.";
  -- Bob suffers 5 frost damage from Jeff's Ice Nova.
  function(source, target, school, attack)
    for target, damage, school, source, attack in string.gfind(arg1, PERIODICAURADAMAGEOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s hits %s for %d.
  function(source, target, school, attack)
    for source, target, damage in string.gfind(arg1, COMBATHITOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s crits %s for %d.
  function(source, target, school, attack)
    for source, target, damage in string.gfind(arg1, COMBATHITCRITOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s hits %s for %d %s damage.
  function(source, target, school, attack)
    for source, target, damage, school in string.gfind(arg1, COMBATHITSCHOOLOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s crits %s for %d %s damage.
  function(source, target, school, attack)
    for source, target, damage, school in string.gfind(arg1, COMBATHITCRITSCHOOLOTHEROTHER) do
      parser:AddData(source, attack, target, damage, school)
      return true
    end
  end,

  -- %s reflects %d %s damage to %s.
  function(source, target, school, attack)
    for source, damage, school, target in string.gfind(arg1, DAMAGESHIELDOTHEROTHER) do
      parser:AddData(source, "Reflection (" .. school .. ")", target, damage, school)
      return true
    end
  end,
}

-- register to all combat log events
parser:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
parser:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS")
parser:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
parser:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
parser:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
parser:RegisterEvent("CHAT_MSG_COMBAT_PARTY_HITS")
parser:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
parser:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")
parser:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
parser:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS")
parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")
parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS")
parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
parser:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
parser:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")

-- call all datasources on each event
parser:SetScript("OnEvent", function()
  if not arg1 then return end

  local source = UnitName("player")
  local target = UnitName("player")
  local school = "physical"
  local attack = "Auto Hit"

  -- detection on all data sources
  for id, func in pairs(datasources) do
    if func(source, target, school, attack) then
      return
    end
  end
end)
