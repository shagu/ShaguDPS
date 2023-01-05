ShaguDPS = {}

-- initialize default question dialog
StaticPopupDialogs["SHAGUMETER_QUESTION"] = {
  button1 = YES,
  button2 = NO,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

-- list of available statusbar textures
local textures = {
  "Interface\\BUTTONS\\WHITE8X8",
  "Interface\\TargetingFrame\\UI-StatusBar",
  "Interface\\Tooltips\\UI-Tooltip-Background",
  "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
}

-- a basic rounding function
local function round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

local function expansion()
  local _, _, _, client = GetBuildInfo()
  client = client or 11200

  -- detect client expansion
  if client >= 20000 and client <= 20400 then
    return "tbc"
  elseif client >= 30000 and client <= 30300 then
    return "wotlk"
  else
    return "vanilla"
  end
end

-- shared variables
local data = {
  damage = {
    [0] = {}, -- overall
    [1] = {}, -- current
  },

  heal = {
    [0] = {}, -- overall
    [1] = {}, -- current
  },

  classes = {},
}

local dmg_table = {}
local view_dmg_all = { }
local view_dps_all = { }
local playerClasses = {}

-- default config
local config = {
  -- size
  width = 180,
  height = 15,
  bars = 8,
  spacing = 0,

  -- tracking
  track_all_units = 0,
  merge_pets = 1,

  -- appearance
  visible = 1,
  texture = 2,
  pastel = 0,

  -- window
  backdrop = 1,
  view = 1,
}

local internals = {
  ["_sum"] = true,
  ["_ctime"] = true,
  ["_tick"] = true,
  ["_esum"] = true,
  ["_effective"] = true,
}

-- create core component frames
local window = CreateFrame("Frame", "ShaguDPSWindow", UIParent)
local settings = CreateFrame("Frame")
local parser = CreateFrame("Frame")

-- make everything public
ShaguDPS.data = data
ShaguDPS.config = config
ShaguDPS.textures = textures
ShaguDPS.window = window
ShaguDPS.settings = settings
ShaguDPS.internals = internals
ShaguDPS.parser = parser
ShaguDPS.round = round
ShaguDPS.expansion = expansion
