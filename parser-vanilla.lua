local parser = ShaguDPS.parser
local parser2 = ShaguDPS.parser2

local function prepare(template)
  template = gsub(template, "%(", "%%(") -- fix ( in string
  template = gsub(template, "%)", "%%)") -- fix ) in string
  template = gsub(template, "%d%$","")
  template = gsub(template, "%%s", "(.+)")
  return gsub(template, "%%d", "(%%d+)")
end

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

--HEALS
local HEALEDSELFSELF = prepare(HEALEDSELFSELF) -- "Your %s heals you for %d."
local HEALEDCRITOTHEROTHER = prepare(HEALEDCRITOTHEROTHER) -- "%s's %s critically heals %s for %d.";
local HEALEDCRITOTHERSELF = prepare(HEALEDCRITOTHERSELF) -- "%s's %s critically heals you for %d.";
local HEALEDCRITSELFOTHER = prepare(HEALEDCRITSELFOTHER) -- "Your %s critically heals %s for %d.";
local HEALEDCRITSELFSELF = prepare(HEALEDCRITSELFSELF) -- "Your %s critically heals you for %d.";
local HEALEDOTHEROTHER = prepare(HEALEDOTHEROTHER) -- "%s's %s heals %s for %d.";
local HEALEDOTHERSELF = prepare(HEALEDOTHERSELF) -- "%s's %s heals you for %d.";
local HEALEDSELFOTHER = prepare(HEALEDSELFOTHER) -- "Your %s heals %s for %d.";

--HOTS
local PERIODICAURAHEALOTHEROTHER = prepare(PERIODICAURAHEALOTHEROTHER) -- "%s gains %d health from %s's %s."; -- Bob gains 10 health from Jane's Rejuvenation.
local PERIODICAURAHEALOTHERSELF = prepare(PERIODICAURAHEALOTHERSELF) -- "You gain %d health from %s's %s."; -- You gain 12 health from John's Rejuvenation.
local PERIODICAURAHEALSELFOTHER = prepare(PERIODICAURAHEALSELFOTHER) -- "%s gains %d health from your %s."; -- Bob gains 10 health from your Rejuvenation.
local PERIODICAURAHEALSELFSELF = prepare(PERIODICAURAHEALSELFSELF) -- "You gain %d health from %s."; -- You gain 10 health from Rejuvenation.

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

local datasources2 = {
  --[[ me source me target ]]--
  -- "Your %s heals you for %d."
  function(source, target, attack)
    for attack, damage in string.gfind(arg1, HEALEDSELFSELF) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "%s's %s critically heals %s for %d."
  function(source, target, attack)
    for source, attack, target, damage in string.gfind(arg1, HEALEDCRITOTHEROTHER) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "%s's %s critically heals you for %d."
  function(source, target, attack)
    for source, attack, damage in string.gfind(arg1, HEALEDCRITOTHERSELF) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "Your %s critically heals %s for %d.";
  function(source, target, attack)
    for attack, target, damage in string.gfind(arg1, HEALEDCRITSELFOTHER) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "Your %s critically heals you for %d.";
  function(source, target, attack)
    for attack, damage, attack in string.gfind(arg1, HEALEDCRITSELFSELF) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  --[[ me source ]]--
  -- "%s's %s heals %s for %d.";
  function(source, target, attack)
    for source, attack, target, damage in string.gfind(arg1, HEALEDOTHEROTHER) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "%s's %s heals you for %d.";
  function(source, target, attack)
    for source, attack, target, damage in string.gfind(arg1, HEALEDOTHERSELF) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "Your %s heals %s for %d.";
  function(source, target, attack)
    for attack, target, damage in string.gfind(arg1, HEALEDSELFOTHER) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "%s gains %d health from %s's %s."; -- Bob gains 10 health from Jane's Rejuvenation.
  function(source, target, attack)
    for target, damage, source, attack in string.gfind(arg1, PERIODICAURAHEALOTHEROTHER) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "You gain %d health from %s's %s."; -- You gain 12 health from John's Rejuvenation.
  function(source, target, attack)
    for damage, source, attack in string.gfind(arg1, PERIODICAURAHEALOTHERSELF) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

   -- "%s gains %d health from your %s."; -- Bob gains 10 health from your Rejuvenation.
  function(source, target, attack)
    for target, damage, source in string.gfind(arg1, PERIODICAURAHEALSELFOTHER) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,

  -- "You gain %d health from %s."; -- You gain 10 health from Rejuvenation.
  function(source, target, attack)
    for damage, source in string.gfind(arg1, PERIODICAURAHEALSELFSELF ) do
      parser2:AddData(source, attack, target, damage)
      return true
    end
  end,
  
  --TODOS
  -- Absorb from power word shield is missing
}
-- register to all combat log damage events
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

-- register to all combat log heal events
parser2:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
parser2:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
parser2:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
parser2:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
parser2:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
parser2:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
parser2:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
parser2:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")

-- call all datasources on each damage event
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

-- call all datasources on each heal event
parser2:SetScript("OnEvent", function()
  if not arg1 then return end

  local source = UnitName("player")
  local target = UnitName("player")
  local school = "heal"
  local attack = " "
  -- detection on all data sources
  for id, func in pairs(datasources2) do
    if func(source, target, school, attack) then
      return
    end
  end
end)