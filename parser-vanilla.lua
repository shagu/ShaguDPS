local parser = ShaguDPS.parser

-- sanitize, cache and convert patterns into gfind compatible ones
local sanitize_cache = {}
function sanitize(pattern)
  if not sanitize_cache[pattern] then
    local ret = pattern
    -- escape magic characters
    ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
    -- remove capture indexes
    ret = gsub(ret, "%d%$","")
    -- catch all characters
    ret = gsub(ret, "(%%%a)","%(%1+%)")
    -- convert all %s to .+
    ret = gsub(ret, "%%s%+",".+")
    -- set priority to numbers over strings
    ret = gsub(ret, "%(.%+%)%(%%d%+%)","%(.-%)%(%%d%+%)")
    -- cache it
    sanitize_cache[pattern] = ret
  end

  return sanitize_cache[pattern]
end

-- find, cache and return the indexes of a regex pattern
local capture_cache = {}
function captures(pat)
  local r = capture_cache
  if not r[pat] then
    -- set default to nil
    r[pat] = { nil, nil, nil, nil, nil }

    -- try to find custom capture indexes
    for a, b, c, d, e in string.gfind(gsub(pat, "%((.+)%)", "%1"), gsub(pat, "%d%$", "%%(.-)$")) do
      r[pat][1] = tonumber(a)
      r[pat][2] = tonumber(b)
      r[pat][3] = tonumber(c)
      r[pat][4] = tonumber(d)
      r[pat][5] = tonumber(e)
    end
  end

  return r[pat][1], r[pat][2], r[pat][3], r[pat][4], r[pat][5]
end

-- same as string.find but aware of up to 5 capture indexes
local ra, rb, rc, rd, re
function cfind(str, pat)
  -- read capture indexes
  local a, b, c, d, e = captures(pat)
  local match, num, va, vb, vc, vd, ve = string.find(str, sanitize(pat))

  -- put entries into the proper return values
  ra = e == 1 and ve or d == 1 and vd or c == 1 and vc or b == 1 and vb or va
  rb = e == 2 and ve or d == 2 and vd or c == 2 and vc or a == 2 and va or vb
  rc = e == 3 and ve or d == 3 and vd or a == 3 and va or b == 3 and vb or vc
  rd = e == 4 and ve or a == 4 and va or c == 4 and vc or b == 4 and vb or vd
  re = a == 5 and va or d == 5 and vd or c == 5 and vc or b == 5 and vb or ve

  return match, num, ra, rb, rc, rd, re
end


local combatlog_strings = {
  -- [[ DAMAGE ]] --

  --[[ me source me target ]]--
  { -- Your %s hits you for %d %s damage.
    SPELLLOGSCHOOLSELFSELF, function(d, attack, value, school)
      return d.source, attack, d.target, value, school, "damage"
    end
  },
  { -- Your %s crits you for %d %s damage.
    SPELLLOGCRITSCHOOLSELFSELF, function(d, attack, value, school)
      return d.source, attack, d.target, value, school, "damage"
    end
  },
  { -- Your %s hits you for %d.
    SPELLLOGSELFSELF, function(d, attack, value)
      return d.source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- Your %s crits you for %d.
    SPELLLOGCRITSELFSELF, function(d, attack, value)
      return d.source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- You suffer %d %s damage from your %s.
    PERIODICAURADAMAGESELFSELF, function(d, value, school, attack)
      return d.source, attack, d.target, value, school, "damage"
    end
  },

  --[[ me source ]]--
  { -- Your %s hits %s for %d %s damage.
    SPELLLOGSCHOOLSELFOTHER, function(d, attack, target, value, school)
      return d.source, attack, target, value, school, "damage"
    end
  },
  { -- Your %s crits %s for %d %s damage.
    SPELLLOGCRITSCHOOLSELFOTHER, function(d, attack, target, value, school)
      return d.source, attack, target, value, school, "damage"
    end
  },
  { -- Your %s hits %s for %d.
    SPELLLOGSELFOTHER, function(d, attack, target, value)
      return d.source, attack, target, value, d.school, "damage"
    end
  },
  { -- Your %s crits %s for %d.
    SPELLLOGCRITSELFOTHER, function(d, attack, target, value)
      return d.source, attack, target, value, d.school, "damage"
    end
  },
  { -- %s suffers %d %s damage from your %s.
    PERIODICAURADAMAGESELFOTHER, function(d, target, value, school, attack)
      return d.source, attack, target, value, school, "damage"
    end
  },
  { -- You hit %s for %d.
    COMBATHITSELFOTHER, function(d, target, value)
      return d.source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- You crit %s for %d.
    COMBATHITCRITSELFOTHER, function(d, target, value)
      return d.source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- You hit %s for %d %s damage.
    COMBATHITSCHOOLSELFOTHER, function(d, target, value, school)
      return d.source, d.attack, target, value, school, "damage"
    end
  },
  { -- You crit %s for %d %s damage.
    COMBATHITCRITSCHOOLSELFOTHER, function(d, target, value, school)
      return d.source, d.attack, target, value, school, "damage"
    end
  },
  { -- You reflect %d %s damage to %s.
    DAMAGESHIELDSELFOTHER, function(d, value, school, target)
      return d.source, "Reflect ("..school..")", target, value, school, "damage"
    end
  },

  --[[ me target ]]--
  { -- %s's %s hits you for %d %s damage.
    SPELLLOGSCHOOLOTHERSELF, function(d, source, attack, value, school)
      return source, attack, d.target, value, school, "damage"
    end
  },
  { -- %s's %s crits you for %d %s damage.
    SPELLLOGCRITSCHOOLOTHERSELF, function(d, source, attack, value, school)
      return source, attack, d.target, value, school, "damage"
    end
  },
  { -- %s's %s hits you for %d.
    SPELLLOGOTHERSELF, function(d, source, attack, value)
      return source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- %s's %s crits you for %d.
    SPELLLOGCRITOTHERSELF, function(d, source, attack, value)
      return source, attack, d.target, value, d.school, "damage"
    end
  },
  { -- You suffer %d %s damage from %s's %s.
    PERIODICAURADAMAGEOTHERSELF, function(d, value, school, source, attack)
      return source, attack, d.target, value, school, "damage"
    end
  },
  { -- %s hits you for %d.
    COMBATHITOTHERSELF, function(d, source, value)
      return source, d.attack, d.target, value, d.school, "damage"
    end
  },
  { -- %s crits you for %d.
    COMBATHITCRITOTHERSELF, function(d, source, value)
      return source, d.attack, d.target, value, d.school, "damage"
    end
  },
  { -- %s hits you for %d %s damage.
    COMBATHITSCHOOLOTHERSELF, function(d, source, value, school)
      return source, d.attack, d.target, value, school, "damage"
    end
  },
  { -- %s crits you for %d %s damage.
    COMBATHITCRITSCHOOLOTHERSELF, function(d, source, value, school)
      return source, d.attack, d.target, value, school, "damage"
    end
  },

  --[[ other ]]--
  { -- %s's %s hits %s for %d %s damage.
    SPELLLOGSCHOOLOTHEROTHER, function(d, source, attack, target, value, school)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s's %s crits %s for %d %s damage.
    SPELLLOGCRITSCHOOLOTHEROTHER, function(d, source, attack, target, value, school)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s's %s hits %s for %d.
    SPELLLOGOTHEROTHER, function(d, source, attack, target, value)
      return source, attack, target, value, d.school, "damage"
    end
  },
  { -- %s's %s crits %s for %d.
    SPELLLOGCRITOTHEROTHER, function(d, source, attack, target, value, school)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s suffers %d %s damage from %s's %s.
    PERIODICAURADAMAGEOTHEROTHER, function(d, target, value, school, source, attack)
      return source, attack, target, value, school, "damage"
    end
  },
  { -- %s hits %s for %d.
    COMBATHITOTHEROTHER, function(d, source, target, value)
      return source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- %s crits %s for %d.
    COMBATHITCRITOTHEROTHER, function(d, source, target, value)
      return source, d.attack, target, value, d.school, "damage"
    end
  },
  { -- %s hits %s for %d %s damage.
    COMBATHITSCHOOLOTHEROTHER, function(d, source, target, value, school)
      return source, d.attack, target, value, school, "damage"
    end
  },
  { -- %s crits %s for %d %s damage.
    COMBATHITCRITSCHOOLOTHEROTHER, function(d, source, target, value, school)
      return source, d.attack, target, value, school, "damage"
    end
  },
  { -- %s reflects %d %s damage to %s.
    DAMAGESHIELDOTHEROTHER, function(d, source, value, school, target)
      return source, "Reflect ("..school..")", target, value, school, "damage"
    end
  },

  -- [[ HEAL ]] --
  --[[ me target ]]--
  { -- %s's %s critically heals you for %d.
    HEALEDCRITOTHERSELF, function(d, source, spell, value)
      return source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- %s's %s heals you for %d.
    HEALEDOTHERSELF, function(d, source, spell, value)
      return source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- You gain %d health from %s's %s.
    PERIODICAURAHEALOTHERSELF, function(d, value, source, spell)
      return source, spell, d.target, value, d.school, "heal"
    end
  },

  --[[ me source me target ]]--
  { -- Your %s critically heals you for %d.
    HEALEDCRITSELFSELF, function(d, spell, value)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- Your %s heals you for %d.
    HEALEDSELFSELF, function(d, spell, value)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },
  { -- You gain %d health from %s.
    PERIODICAURAHEALSELFSELF, function(d, value, spell)
      return d.source, spell, d.target, value, d.school, "heal"
    end
  },

  --[[ me source ]]--
  { -- Your %s critically heals %s for %d.
    HEALEDCRITSELFOTHER, function(d, spell, target, value)
      return d.source, spell, target, value, d.school, "heal"
    end
  },
  { -- Your %s heals %s for %d.
    HEALEDSELFOTHER, function(d, spell, target, value)
      return d.source, spell, target, value, d.school, "heal"
    end
  },
  { -- %s gains %d health from your %s.
    PERIODICAURAHEALSELFOTHER, function(d, target, value, spell)
      return d.source, spell, target, value, d.school, "heal"
    end
  },

  --[[ other ]]--
  { -- %s's %s critically heals %s for %d.
    HEALEDCRITOTHEROTHER, function(d, source, spell, target, value)
      return source, spell, target, value, d.school, "heal"
    end
  },
  { -- %s's %s heals %s for %d.
    HEALEDOTHEROTHER, function(d, source, spell, target, value)
      return source, spell, target, value, d.school, "heal"
    end
  },
  { -- %s gains %d health from %s's %s.
    PERIODICAURAHEALOTHEROTHER, function(d, target, value, source, spell)
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
    local result, _, a1, a2, a3, a4, a5 = cfind(arg1, data[1])

    if result then
      return parser:AddData(data[2](defaults, a1, a2, a3, a4, a5))
    end
  end
end)
