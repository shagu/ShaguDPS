local parser = ShaguDPS.parser

local function prepare(template)
  template = gsub(template, "%(", "%%(") -- fix ( in string
  template = gsub(template, "%)", "%%)") -- fix ) in string
  template = gsub(template, "%d%$","")
  template = gsub(template, "%%s", "(.+)")
  return gsub(template, "%%d", "(%%d+)")
end

local combatlog_strings = {
  -- [[ DAMAGE ]] --

  -- TODO: check source/target of each spell

  --[[ me source me target ]]--
  { -- Your %s hits you for %d %s damage.
    prepare(SPELLLOGSCHOOLSELFSELF), function(d, attack, value, school)
      return d.source, attack, d.target, value, school, "damage"
    end
  },
  { -- Your %s crits you for %d %s damage.
    prepare(SPELLLOGCRITSCHOOLSELFSELF), function(d, attack, value, school)
      return d.source, attack, d.target, value, school, "damage"
    end
  },
  { -- Your %s hits you for %d.
    prepare(SPELLLOGSELFSELF), function(d, attack, value)
      return d.source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- Your %s crits you for %d.
    prepare(SPELLLOGCRITSELFSELF), function(d, attack, value)
      return d.source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- You suffer %d %s damage from your %s.
    prepare(PERIODICAURADAMAGESELFSELF), function(d, value, school, attack)
      return d.source, attack, d.target, value, school, "damage"
    end
  },

  --[[ me source ]]--
  { -- Your %s hits %s for %d %s damage.
    prepare(SPELLLOGSCHOOLSELFOTHER), function(d, attack, target, value, school)
      return d.source, attack, target, value, school, "damage"
    end
  },
  { -- Your %s crits %s for %d %s damage.
    prepare(SPELLLOGCRITSCHOOLSELFOTHER), function(d, attack, target, value, school)
      return d.source, attack, target, value, school, "damage"
    end
  },
  { -- Your %s hits %s for %d.
    prepare(SPELLLOGSELFOTHER), function(d, attack, target, value)
      return d.source, attack, target, value, d.school, "damage"
    end
  },
  { -- Your %s crits %s for %d.
    prepare(SPELLLOGCRITSELFOTHER), function(d, attack, target, value)
      return d.source, attack, target, value, d.school, "damage"
    end
  },
  { -- %s suffers %d %s damage from your %s.
    prepare(PERIODICAURADAMAGESELFOTHER), function(d, target, value, school, attack)
      return d.source, attack, target, value, school, "damage"
    end
  },
  { -- You hit %s for %d.
    prepare(COMBATHITSELFOTHER), function(d, target, value)
      return d.source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- You crit %s for %d.
    prepare(COMBATHITCRITSELFOTHER), function(d, target, value)
      return d.source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- You hit %s for %d %s damage.
    prepare(COMBATHITSCHOOLSELFOTHER), function(d, target, value, school)
      return d.source, d.attack, target, value, school, "damage"
    end
  },
  { -- You crit %s for %d %s damage.
    prepare(COMBATHITCRITSCHOOLSELFOTHER), function(d, target, value, school)
      return d.source, d.attack, target, value, school, "damage"
    end
  },
  { -- You reflect %d %s damage to %s.
    prepare(DAMAGESHIELDSELFOTHER), function(d, value, school, target)
      return d.source, "Reflect ("..school..")", target, value, school, "damage"
    end
  },

  --[[ me target ]]--
  { -- %s's %s hits you for %d %s damage.
    prepare(SPELLLOGSCHOOLOTHERSELF), function(d, source, attack, value, school)
      return source, attack, d.target, value, school, "damage"
    end
  },
  { -- %s's %s crits you for %d %s damage.
    prepare(SPELLLOGCRITSCHOOLOTHERSELF), function(d, source, attack, value, school)
      return source, attack, d.target, value, school, "damage"
    end
  },
  { -- %s's %s hits you for %d.
    prepare(SPELLLOGOTHERSELF), function(d, source, attack, value)
      return source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- %s's %s crits you for %d.
    prepare(SPELLLOGCRITOTHERSELF), function(d, source, attack, value)
      return source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- You suffer %d %s damage from %s's %s.
    prepare(PERIODICAURADAMAGEOTHERSELF), function(d, value, school, source, attack)
      return source, attack, d.target, value, school, "damage"
    end
  },
  { -- %s hits you for %d.
    prepare(COMBATHITOTHERSELF), function(d, source, value)
      return source, d.attack, d.target, value, d.school, "damage"
    end
  },
  { -- %s crits you for %d.
    prepare(COMBATHITCRITOTHERSELF), function(d, source, value)
      return source, d.attack, d.target, value, d.school, "damage"
    end
  },
  { -- %s hits you for %d %s damage.
    prepare(COMBATHITSCHOOLOTHERSELF), function(d, source, value, school)
      return source, d.attack, d.target, value, school, "damage"
    end
  },
  { -- %s crits you for %d %s damage.
    prepare(COMBATHITCRITSCHOOLOTHERSELF), function(d, source, value, school)
      return source, d.attack, d.target, value, school, "damage"
    end
  },

  --[[ other ]]--
  { -- %s's %s hits %s for %d %s damage.
    prepare(SPELLLOGSCHOOLOTHEROTHER), function(d, source, attack, target, value, school)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s's %s crits %s for %d %s damage.
    prepare(SPELLLOGCRITSCHOOLOTHEROTHER), function(d, source, attack, target, value, school)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s's %s hits %s for %d.
    prepare(SPELLLOGOTHEROTHER), function(d, source, attack, target, value)
      return source, attack, target, value, d.school, "damage"
    end
  },
  { -- %s's %s crits %s for %d.
    prepare(SPELLLOGCRITOTHEROTHER), function(d, source, attack, target, value, school)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s suffers %d %s damage from %s's %s.
    prepare(PERIODICAURADAMAGEOTHEROTHER), function(d, target, value, school, source, attack)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s hits %s for %d.
    prepare(COMBATHITOTHEROTHER), function(d, source, target, value)
      return source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- %s crits %s for %d.
    prepare(COMBATHITCRITOTHEROTHER), function(d, source, target, value)
      return source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- %s hits %s for %d %s damage.
    prepare(COMBATHITSCHOOLOTHEROTHER), function(d, source, target, value, school)
      return source, d.attack, target, value, school, "damage"
    end
  },
  { -- %s crits %s for %d %s damage.
    prepare(COMBATHITCRITSCHOOLOTHEROTHER), function(d, source, target, value, school)
      return source, d.attack, target, value, school, "damage"
    end
  },
  { -- %s reflects %d %s damage to %s.
    prepare(DAMAGESHIELDOTHEROTHER), function(d, source, value, school, target)
      return source, "Reflect ("..school..")", target, value, school, "damage"
    end
  },

  -- [[ HEAL ]] --

  --[[ me source me target ]]--
  { -- Your %s critically heals you for %d.
    prepare(HEALEDCRITSELFSELF), function(d, spell, value)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- Your %s heals you for %d.
    prepare(HEALEDSELFSELF), function(d, spell, value)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- You gain %d health from %s.
    prepare(PERIODICAURAHEALSELFSELF), function(d, value, spell)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },

  --[[ me source ]]--
  { -- Your %s critically heals %s for %d.
    prepare(HEALEDCRITSELFOTHER), function(d, spell, target, value)
      return d.source, spell, target, value, d.school, "heal"
    end
  },
  { -- Your %s heals %s for %d.
    prepare(HEALEDSELFOTHER), function(d, spell, target, value)
      return d.source, spell, target, value, d.school, "heal"
    end
  },
  { -- %s gains %d health from your %s.
    prepare(PERIODICAURAHEALSELFOTHER), function(d, target, value, spell)
      return d.source, spell, target, value, d.school, "heal"
    end
  },

  --[[ me target ]]--
  { -- %s's %s critically heals you for %d.
    prepare(HEALEDCRITOTHERSELF), function(d, source, spell, value)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- %s's %s heals you for %d.
    prepare(HEALEDOTHERSELF), function(d, source, spell, value)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- You gain %d health from %s's %s.
    prepare(PERIODICAURAHEALOTHERSELF), function(d, value, source, spell)
      return source, spell, d.target, value, d.school, "heal"
    end
  },

  --[[ other ]]--
  { -- %s's %s critically heals %s for %d.
    prepare(HEALEDCRITOTHEROTHER), function(d, source, spell, target, value)
      return source, spell, target, value, d.school, "heal"
    end
  },
  { -- %s's %s heals %s for %d.
    prepare(HEALEDOTHEROTHER), function(d, source, spell, target, value)
      return source, spell, target, value, d.school, "heal"
    end
  },
  { -- %s gains %d health from %s's %s.
    prepare(PERIODICAURAHEALOTHEROTHER), function(d, target, value, source, spell)
      return source, spell, target, value, d.school, "heal"
    end
  },
}

-- register to all damage combat log events
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

-- register to all heal combat log events
parser:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
parser:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
parser:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
parser:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")

-- cache default table
local defaults = { }

-- call all datasources on each event
parser:SetScript("OnEvent", function()
  if not arg1 then return end

  defaults.source = UnitName("player")
  defaults.target = UnitName("player")
  defaults.school = "physical"
  defaults.attack = "Auto Hit"
  defaults.spell  = UNKNOWN
  defaults.value = 0

  -- detection on all damage sources
  for id, data in pairs(combatlog_strings) do
    local result, _, a1, a2, a3, a4, a5 = string.find(arg1, data[1])
    if result then
      return parser:AddData(data[2](defaults, a1, a2, a3, a4, a5))
    end
  end
end)
