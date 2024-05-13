local parser = ShaguDPS.parser

-- sanitize, cache and convert patterns into gfind compatible ones
local sanitize_cache = {}
function sanitize(pattern)
	if not sanitize_cache[pattern] then
		local ret = pattern
		-- escape magic characters
		ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
		-- remove capture indexes
		ret = gsub(ret, "%d%$", "")
		-- catch all characters
		ret = gsub(ret, "(%%%a)", "%(%1+%)")
		-- convert all %s to .+
		ret = gsub(ret, "%%s%+", ".+")
		-- set priority to numbers over strings
		ret = gsub(ret, "%(.%+%)%(%%d%+%)", "%(.-%)%(%%d%+%)")
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

-- damage events
local selfSpellDamageEventFrame = CreateFrame("Frame")
local selfHitsDamageEventFrame = CreateFrame("Frame")
local selfDamageShieldDamageEventFrame = CreateFrame("Frame")

local spellDamageEventFrame = CreateFrame("Frame")
local periodicDamageEventFrame = CreateFrame("Frame")
local hitsDamageEventFrame = CreateFrame("Frame")
local damageShieldDamageEventFrame = CreateFrame("Frame")

function parser:RegisterDamageEvents()
	selfSpellDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
	selfHitsDamageEventFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
	selfDamageShieldDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")

	periodicDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
	periodicDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
	periodicDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
	periodicDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
	periodicDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")

	hitsDamageEventFrame:RegisterEvent("CHAT_MSG_COMBAT_PARTY_HITS")
	hitsDamageEventFrame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS")
	hitsDamageEventFrame:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")
	hitsDamageEventFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS")
	hitsDamageEventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")

	spellDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
	spellDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
	spellDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
	spellDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
	spellDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")

	damageShieldDamageEventFrame:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS")
end

function parser:UnregisterDamageEvents()
	selfSpellDamageEventFrame:UnregisterAllEvents()
	selfHitsDamageEventFrame:UnregisterAllEvents()
	selfDamageShieldDamageEventFrame:UnregisterAllEvents()

	periodicDamageEventFrame:UnregisterAllEvents()
	hitsDamageEventFrame:UnregisterAllEvents()
	spellDamageEventFrame:UnregisterAllEvents()
	damageShieldDamageEventFrame:UnregisterAllEvents()
end

-- heal events
local selfHealEventFrame = CreateFrame("Frame")
local selfPeriodicHealEventFrame = CreateFrame("Frame")

local healEventFrame = CreateFrame("Frame")
local periodicHealEventFrame = CreateFrame("Frame")

function parser:RegisterHealEvents()
	selfHealEventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
	selfPeriodicHealEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")

	periodicHealEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")
	periodicHealEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
	periodicHealEventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")

	healEventFrame:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
	healEventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
	healEventFrame:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
end

function parser:UnregisterHealEvents()
	selfHealEventFrame:UnregisterAllEvents()
	selfPeriodicHealEventFrame:UnregisterAllEvents()

	periodicHealEventFrame:UnregisterAllEvents()
	healEventFrame:UnregisterAllEvents()
end

if ShaguDPS.config.view == 1 or ShaguDPS.config.view == 2 then
	parser:RegisterDamageEvents()
else
	parser:RegisterHealEvents()
end

-- cache default table
local defaults = {
	source = UnitName("player"),
	target = UnitName("player"),
	school = "physical",
	attack = "Auto Hit",
	spell = UNKNOWN,
	value = 0,
}

function parser:OnDamageEvent(parse_strings, event)
	if not event then
		return
	end

	-- detection on all damage sources
	for id, data in pairs(parse_strings) do
		local result, _, a1, a2, a3, a4, a5 = cfind(arg1, data[1])

		if result then
			return parser:AddData(data[2](defaults, a1, a2, a3, a4, a5))
		end
	end
end

function parser:OnHealEvent(parse_strings)
	if not arg1 then
		return
	end

	-- detection on all damage sources
	for id, data in pairs(parse_strings) do
		local result, _, a1, a2, a3, a4, a5 = cfind(arg1, data[1])

		if result then
			return parser:AddData(data[2](defaults, a1, a2, a3, a4, a5))
		end
	end
end

local self_damage_spell_strings = {
	-- [[ SELF DAMAGE SPELLS]] --
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
}

selfSpellDamageEventFrame:SetScript("OnEvent", function()
	parser:OnDamageEvent(self_damage_spell_strings, arg1)
end)

local self_hits_damage_strings = {
	{ -- You hit %s for %d.
		COMBATHITSELFOTHER, function(d, target, value)
		return d.source, d.attack, target, value, d.school, "damage"
	end
	},
	{ -- You hit %s for %d %s damage.
		COMBATHITSCHOOLSELFOTHER, function(d, target, value, school)
		return d.source, d.attack, target, value, school, "damage"
	end
	},
	{ -- You crit %s for %d.
		COMBATHITCRITSELFOTHER, function(d, target, value)
		return d.source, d.attack, target, value, d.school, "damage"
	end
	},
	{ -- You crit %s for %d %s damage.
		COMBATHITCRITSCHOOLSELFOTHER, function(d, target, value, school)
		return d.source, d.attack, target, value, school, "damage"
	end
	},
}

selfHitsDamageEventFrame:SetScript("OnEvent", function()
	parser:OnDamageEvent(self_hits_damage_strings, arg1)
end)

local self_damage_shield_strings = {
	{ -- You reflect %d %s damage to %s.
		DAMAGESHIELDSELFOTHER, function(d, value, school, target)
		return d.source, "Reflect (" .. school .. ")", target, value, school, "damage"
	end
	},
}

selfDamageShieldDamageEventFrame:SetScript("OnEvent", function()
	parser:OnDamageEvent(self_damage_shield_strings, arg1)
end)

local damage_spell_strings = {
	-- [[ OTHER DAMAGE SPELLS]] --
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
}

spellDamageEventFrame:SetScript("OnEvent", function()
	parser:OnDamageEvent(damage_spell_strings, arg1)
end)

local periodic_damage_strings = {
	{ -- %s suffers %d %s damage from %s's %s.
		PERIODICAURADAMAGEOTHEROTHER, function(d, target, value, school, source, attack)
		return source, attack, target, value, school, "damage"
	end
	},
	{ -- %s suffers %d %s damage from your %s.
		PERIODICAURADAMAGESELFOTHER, function(d, target, value, school, attack)
		return d.source, attack, target, value, school, "damage"
	end
	},
}

periodicDamageEventFrame:SetScript("OnEvent", function()
	parser:OnDamageEvent(periodic_damage_strings, arg1)
end)

local hits_damage_strings = {
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
}

hitsDamageEventFrame:SetScript("OnEvent", function()
	parser:OnDamageEvent(hits_damage_strings, arg1)
end)

local damage_shield_strings = {
	{ -- %s reflects %d %s damage to %s.
		DAMAGESHIELDOTHEROTHER, function(d, source, value, school, target)
		return source, "Reflect (" .. school .. ")", target, value, school, "damage"
	end
	},
}

damageShieldDamageEventFrame:SetScript("OnEvent", function()
	parser:OnDamageEvent(damage_shield_strings, arg1)
end)

local self_heal_strings = {
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
}

selfHealEventFrame:SetScript("OnEvent", function()
	parser:OnHealEvent(self_heal_strings, arg1)
end)

local self_periodic_heal_strings = {
	{ -- You gain %d health from %s.
		PERIODICAURAHEALSELFSELF, function(d, value, spell)
		return d.source, spell, d.target, value, d.school, "heal"
	end
	},
	{ -- You gain %d health from %s's %s.
		PERIODICAURAHEALOTHERSELF, function(d, value, source, spell)
		return source, spell, d.target, value, d.school, "heal"
	end
	},
}

selfPeriodicHealEventFrame:SetScript("OnEvent", function()
	parser:OnHealEvent(self_periodic_heal_strings, arg1)
end)

local periodic_heal_strings = {
	{ -- %s gains %d health from %s's %s.
		PERIODICAURAHEALOTHEROTHER, function(d, target, value, source, spell)
		return source, spell, target, value, d.school, "heal"
	end
	},
	{ -- %s gains %d health from your %s.
		PERIODICAURAHEALSELFOTHER, function(d, target, value, spell)
		return d.source, spell, target, value, d.school, "heal"
	end
	},
}

periodicHealEventFrame:SetScript("OnEvent", function()
	parser:OnHealEvent(periodic_heal_strings, arg1)
end)

local heal_strings = {
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
}

healEventFrame:SetScript("OnEvent", function()
	parser:OnHealEvent(heal_strings, arg1)
end)
