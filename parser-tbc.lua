local parser = ShaguDPS.parser

local function hit(_, _, _, source, _, _, target, _, damage, school)
  parser:AddData(source, "Auto Hit", target, damage, school, "damage")
end

local function spell(_, _, _, source, _, _, target, _, _, attack, _, damage, school)
  parser:AddData(source, attack, target, damage, school, "damage")
end

local function other(_, _, _, source, _, _, target, _, attack, damage, _, school)
  parser:AddData(source, attack, target, damage, school, "damage")
end

local function heal(_, _, _, source, _, _, target, _, _, spell, _, value)
  parser:AddData(source, spell, target, value, nil, "heal")
end

local datasources = {
  ["SWING_DAMAGE"]          = hit,
  ["SPELL_DAMAGE"]          = spell,
  ["RANGE_DAMAGE"]          = spell,
  ["DAMAGE_SHIELD"]         = spell,
  ["DAMAGE_SPLIT"]          = spell,
  ["SPELL_PERIODIC_DAMAGE"] = spell,
  ["ENVIRONMENTAL_DAMAGE"]  = other,
  ["SPELL_HEAL"]            = heal,
  ["SPELL_PERIODIC_HEAL"]   = heal,
}

parser:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
parser:SetScript("OnEvent", function(event)
  if not arg2 then return end
  if datasources[arg2] then
    datasources[arg2](arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12,arg13)
  end
end)
