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
local ra, rb, rc, rd, re, a, b, c, d, e, match, num, va, vb, vc, vd, ve
function cfind(str, pat)
  -- read capture indexes
  a, b, c, d, e = captures(pat)
  match, num, va, vb, vc, vd, ve = string.find(str, sanitize(pat))

  -- put entries into the proper return values
  ra = e == 1 and ve or d == 1 and vd or c == 1 and vc or b == 1 and vb or va
  rb = e == 2 and ve or d == 2 and vd or c == 2 and vc or a == 2 and va or vb
  rc = e == 3 and ve or d == 3 and vd or a == 3 and va or b == 3 and vb or vc
  rd = e == 4 and ve or a == 4 and va or c == 4 and vc or b == 4 and vb or vd
  re = a == 5 and va or d == 5 and vd or c == 5 and vc or b == 5 and vb or ve

  return match, num, ra, rb, rc, rd, re
end

-- list of possible combat log patterns that may appear on the same events
local combatlog_strings = {
  -- Damage
  ["Hit Damage (self vs. other)"] = {
    COMBATHITSELFOTHER, COMBATHITSCHOOLSELFOTHER, COMBATHITCRITSELFOTHER, COMBATHITCRITSCHOOLSELFOTHER
  },
  ["Hit Damage (other vs. self)"] = {
    COMBATHITOTHERSELF, COMBATHITCRITOTHERSELF, COMBATHITSCHOOLOTHERSELF, COMBATHITCRITSCHOOLOTHERSELF
  },
  ["Hit Damage (other vs. other)"] = {
    COMBATHITOTHEROTHER, COMBATHITCRITOTHEROTHER, COMBATHITSCHOOLOTHEROTHER, COMBATHITCRITSCHOOLOTHEROTHER
  },
  ["Spell Damage (self vs. self/other)"] = {
    SPELLLOGSCHOOLSELFSELF, SPELLLOGCRITSCHOOLSELFSELF, SPELLLOGSELFSELF, SPELLLOGCRITSELFSELF, SPELLLOGSCHOOLSELFOTHER, SPELLLOGCRITSCHOOLSELFOTHER, SPELLLOGSELFOTHER, SPELLLOGCRITSELFOTHER
  },
  ["Spell Damage (other vs. self)"] = {
    SPELLLOGSCHOOLOTHERSELF, SPELLLOGCRITSCHOOLOTHERSELF, SPELLLOGOTHERSELF, SPELLLOGCRITOTHERSELF
  },
  ["Spell Damage (other vs. other)"] = {
    SPELLLOGSCHOOLOTHEROTHER, SPELLLOGCRITSCHOOLOTHEROTHER, SPELLLOGOTHEROTHER, SPELLLOGCRITOTHEROTHER
  },
  ["Shield Damage (self vs. other)"] = {
    DAMAGESHIELDSELFOTHER
  },
  ["Shield Damage (other vs. self/other)"] = {
    DAMAGESHIELDOTHERSELF, DAMAGESHIELDOTHEROTHER
  },
  ["Periodic Damage (self/other vs. other)"] = {
    PERIODICAURADAMAGESELFOTHER, PERIODICAURADAMAGEOTHEROTHER
  },
  ["Periodic Damage (self/other vs. self)"] = {
    PERIODICAURADAMAGESELFSELF, PERIODICAURADAMAGEOTHERSELF
  },

  -- Heal
  ["Heal (self vs. self/other)"] = {
    HEALEDCRITSELFSELF, HEALEDSELFSELF, HEALEDCRITSELFOTHER, HEALEDSELFOTHER
  },
  ["Heal (other vs. self/other)"] = {
    HEALEDCRITOTHERSELF, HEALEDOTHERSELF, HEALEDCRITOTHEROTHER, HEALEDOTHEROTHER
  },
  ["Periodic Heal (self/other vs. other)"] = {
    PERIODICAURAHEALSELFOTHER, PERIODICAURAHEALOTHEROTHER
  },
  ["Periodic Heal (other vs. self/other)"] = {
    PERIODICAURAHEALSELFSELF, PERIODICAURAHEALOTHERSELF
  }
}

-- list of combat log events with possible patterns assigned to them
local combatlog_events = {
  -- Damage
  ["CHAT_MSG_COMBAT_SELF_HITS"] = combatlog_strings["Hit Damage (self vs. other)"],
  ["CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS"] = combatlog_strings["Hit Damage (other vs. self)"],
  ["CHAT_MSG_COMBAT_PARTY_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
  ["CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
  ["CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
  ["CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
  ["CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
  ["CHAT_MSG_COMBAT_PET_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
  ["CHAT_MSG_SPELL_SELF_DAMAGE"] = combatlog_strings["Spell Damage (self vs. self/other)"],
  ["CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE"] = combatlog_strings["Spell Damage (other vs. self)"],
  ["CHAT_MSG_SPELL_PARTY_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
  ["CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
  ["CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
  ["CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
  ["CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
  ["CHAT_MSG_SPELL_PET_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
  ["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"] = combatlog_strings["Shield Damage (self vs. other)"],
  ["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS"] = combatlog_strings["Shield Damage (other vs. self/other)"],
  ["CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
  ["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
  ["CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
  ["CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
  ["CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. self)"],

  -- Heal
  ["CHAT_MSG_SPELL_SELF_BUFF"] = combatlog_strings["Heal (self vs. self/other)"],
  ["CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF"] = combatlog_strings["Heal (other vs. self/other)"],
  ["CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"] = combatlog_strings["Heal (other vs. self/other)"],
  ["CHAT_MSG_SPELL_PARTY_BUFF"] = combatlog_strings["Heal (other vs. self/other)"],
  ["CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS"] = combatlog_strings["Periodic Heal (self/other vs. other)"],
  ["CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS"] = combatlog_strings["Periodic Heal (self/other vs. other)"],
  ["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS"] = combatlog_strings["Periodic Heal (self/other vs. other)"],
  ["CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"] = combatlog_strings["Periodic Heal (other vs. self/other)"]
}

-- list of all possible patterns including the logic on how to parse them
local combatlog_parser = {
  [SPELLLOGSCHOOLSELFSELF] = function(d, attack, value, school)
    -- Your %s hits you for %d %s damage.
    return d.source, attack, d.target, value, school, "damage"
  end,

  [SPELLLOGCRITSCHOOLSELFSELF] = function(d, attack, value, school)
    -- Your %s crits you for %d %s damage.
    return d.source, attack, d.target, value, school, "damage"
  end,

  [SPELLLOGSELFSELF] = function(d, attack, value)
    -- Your %s hits you for %d.
    return d.source, attack, d.target, value, d.school, "damage"
  end,

  [SPELLLOGCRITSELFSELF] = function(d, attack, value)
    -- Your %s crits you for %d.
    return d.source, attack, d.target, value, d.school, "damage"
  end,

  [PERIODICAURADAMAGESELFSELF] = function(d, value, school, attack)
    -- You suffer %d %s damage from your %s.
    return d.source, attack, d.target, value, school, "damage"
  end,

  [SPELLLOGSCHOOLSELFOTHER] = function(d, attack, target, value, school)
    -- Your %s hits %s for %d %s damage.
    return d.source, attack, target, value, school, "damage"
  end,

  [SPELLLOGCRITSCHOOLSELFOTHER] = function(d, attack, target, value, school)
    -- Your %s crits %s for %d %s damage.
    return d.source, attack, target, value, school, "damage"
  end,

  [SPELLLOGSELFOTHER] = function(d, attack, target, value)
    -- Your %s hits %s for %d.
    return d.source, attack, target, value, d.school, "damage"
  end,

  [SPELLLOGCRITSELFOTHER] = function(d, attack, target, value)
    -- Your %s crits %s for %d.
    return d.source, attack, target, value, d.school, "damage"
  end,

  [PERIODICAURADAMAGESELFOTHER] = function(d, target, value, school, attack)
    -- %s suffers %d %s damage from your %s.
    return d.source, attack, target, value, school, "damage"
  end,

  [COMBATHITSELFOTHER] = function(d, target, value)
    -- You hit %s for %d.
    return d.source, d.attack, target, value, d.school, "damage"
  end,

  [COMBATHITCRITSELFOTHER] = function(d, target, value)
    -- You crit %s for %d.
    return d.source, d.attack, target, value, d.school, "damage"
  end,

  [COMBATHITSCHOOLSELFOTHER] = function(d, target, value, school)
    -- You hit %s for %d %s damage.
    return d.source, d.attack, target, value, school, "damage"
  end,

  [COMBATHITCRITSCHOOLSELFOTHER] = function(d, target, value, school)
    -- You crit %s for %d %s damage.
    return d.source, d.attack, target, value, school, "damage"
  end,

  [DAMAGESHIELDSELFOTHER] = function(d, value, school, target)
    -- You reflect %d %s damage to %s.
    return d.source, "Reflect ("..school..")", target, value, school, "damage"
  end,

  [SPELLLOGSCHOOLOTHERSELF] = function(d, source, attack, value, school)
    -- %s's %s hits you for %d %s damage.
    return source, attack, d.target, value, school, "damage"
  end,

  [SPELLLOGCRITSCHOOLOTHERSELF] = function(d, source, attack, value, school)
    -- %s's %s crits you for %d %s damage.
    return source, attack, d.target, value, school, "damage"
  end,

  [SPELLLOGOTHERSELF] = function(d, source, attack, value)
    -- %s's %s hits you for %d.
    return source, attack, d.target, value, d.school, "damage"
  end,

  [SPELLLOGCRITOTHERSELF] = function(d, source, attack, value)
    -- %s's %s crits you for %d.
    return source, attack, d.target, value, d.school, "damage"
  end,

  [PERIODICAURADAMAGEOTHERSELF] = function(d, value, school, source, attack)
    -- You suffer %d %s damage from %s's %s.
    return source, attack, d.target, value, school, "damage"
  end,

  [COMBATHITOTHERSELF] = function(d, source, value)
    -- %s hits you for %d.
    return source, d.attack, d.target, value, d.school, "damage"
  end,

  [COMBATHITCRITOTHERSELF] = function(d, source, value)
    -- %s crits you for %d.
    return source, d.attack, d.target, value, d.school, "damage"
  end,

  [COMBATHITSCHOOLOTHERSELF] = function(d, source, value, school)
    -- %s hits you for %d %s damage.
    return source, d.attack, d.target, value, school, "damage"
  end,

  [COMBATHITCRITSCHOOLOTHERSELF] = function(d, source, value, school)
    -- %s crits you for %d %s damage.
    return source, d.attack, d.target, value, school, "damage"
  end,

  [SPELLLOGSCHOOLOTHEROTHER] = function(d, source, attack, target, value, school)
    -- %s's %s hits %s for %d %s damage.
    return source, attack, target, value, school, "damage"
  end,

  [SPELLLOGCRITSCHOOLOTHEROTHER] = function(d, source, attack, target, value, school)
    -- %s's %s crits %s for %d %s damage.
    return source, attack, target, value, school, "damage"
  end,

  [SPELLLOGOTHEROTHER] = function(d, source, attack, target, value)
    -- %s's %s hits %s for %d.
    return source, attack, target, value, d.school, "damage"
  end,

  [SPELLLOGCRITOTHEROTHER] = function(d, source, attack, target, value, school)
    -- %s's %s crits %s for %d.
    return source, attack, target, value, school, "damage"
  end,

  [PERIODICAURADAMAGEOTHEROTHER] = function(d, target, value, school, source, attack)
    -- %s suffers %d %s damage from %s's %s.
    return source, attack, target, value, school, "damage"
  end,

  [COMBATHITOTHEROTHER] = function(d, source, target, value)
    -- %s hits %s for %d.
    return source, d.attack, target, value, d.school, "damage"
  end,

  [COMBATHITCRITOTHEROTHER] = function(d, source, target, value)
    -- %s crits %s for %d.
    return source, d.attack, target, value, d.school, "damage"
  end,

  [COMBATHITSCHOOLOTHEROTHER] = function(d, source, target, value, school)
    -- %s hits %s for %d %s damage.
    return source, d.attack, target, value, school, "damage"
  end,

  [COMBATHITCRITSCHOOLOTHEROTHER] = function(d, source, target, value, school)
    -- %s crits %s for %d %s damage.
    return source, d.attack, target, value, school, "damage"
  end,

  [DAMAGESHIELDOTHERSELF] = function(d, source, value, school)
    -- %s reflects %d %s damage to you.
    return source, "Reflect ("..school..")", d.target, value, school, "damage"
  end,

  [DAMAGESHIELDOTHEROTHER] = function(d, source, value, school, target)
    -- %s reflects %d %s damage to %s.
    return source, "Reflect ("..school..")", target, value, school, "damage"
  end,

  [HEALEDCRITOTHERSELF] = function(d, source, spell, value)
    -- %s's %s critically heals you for %d.
    return source, spell, d.target, value, d.school, "heal"
  end,

  [HEALEDOTHERSELF] = function(d, source, spell, value)
    -- %s's %s heals you for %d.
    return source, spell, d.target, value, d.school, "heal"
  end,

  [PERIODICAURAHEALOTHERSELF] = function(d, value, source, spell)
    -- You gain %d health from %s's %s.
    return source, spell, d.target, value, d.school, "heal"
  end,

  [HEALEDCRITSELFSELF] = function(d, spell, value)
    -- Your %s critically heals you for %d.
    return d.source, spell, d.target, value, d.school, "heal"
  end,

  [HEALEDSELFSELF] = function(d, spell, value)
    -- Your %s heals you for %d.
    return d.source, spell, d.target, value, d.school, "heal"
  end,

  [PERIODICAURAHEALSELFSELF] = function(d, value, spell)
    -- You gain %d health from %s.
    return d.source, spell, d.target, value, d.school, "heal"
  end,

  [HEALEDCRITSELFOTHER] = function(d, spell, target, value)
    -- Your %s critically heals %s for %d.
    return d.source, spell, target, value, d.school, "heal"
  end,

  [HEALEDSELFOTHER] = function(d, spell, target, value)
    -- Your %s heals %s for %d.
    return d.source, spell, target, value, d.school, "heal"
  end,

  [PERIODICAURAHEALSELFOTHER] = function(d, target, value, spell)
    -- %s gains %d health from your %s.
    return d.source, spell, target, value, d.school, "heal"
  end,

  [HEALEDCRITOTHEROTHER] = function(d, source, spell, target, value)
    -- %s's %s critically heals %s for %d.
    return source, spell, target, value, d.school, "heal"
  end,

  [HEALEDOTHEROTHER] = function(d, source, spell, target, value)
    -- %s's %s heals %s for %d.
    return source, spell, target, value, d.school, "heal"
  end,

  [PERIODICAURAHEALOTHEROTHER] = function(d, target, value, source, spell)
    -- %s gains %d health from %s's %s.
    return source, spell, target, value, d.school, "heal"
  end,
}

-- register to all combat log events
for event in pairs(combatlog_events) do
  parser:RegisterEvent(event)
end

-- preload all combat log patterns
for pattern in pairs(combatlog_parser) do
  sanitize(pattern)
end

-- cache default table
local defaults = { }

-- initialize absorb and resist pattern
local absorb = sanitize(ABSORB_TRAILER)
local resist = sanitize(RESIST_TRAILER)

-- scope all required variables
local _, num, pattern, result, a1, a2, a3, a4, a5

-- use same strings each time
local empty, physical, autohit = "", "physical", "Auto Hit"
local player = UnitName("player")

-- call all datasources on each event
parser:SetScript("OnEvent", function()
  if not arg1 then return end

  -- remove absorb and resist suffixes
  arg1 = string.gsub(arg1, absorb, empty)
  arg1 = string.gsub(arg1, resist, empty)

  -- write default values
  defaults.source = player
  defaults.target = player
  defaults.school = physical
  defaults.attack = autohit
  defaults.spell  = UNKNOWN
  defaults.value  = 0

  -- iterate over all patterns assigned to the current event
  for _, pattern in pairs(combatlog_events[event]) do
    result, num, a1, a2, a3, a4, a5 = cfind(arg1, pattern)

    if result then
      return parser:AddData(combatlog_parser[pattern](defaults, a1, a2, a3, a4, a5))
    end
  end
end)
