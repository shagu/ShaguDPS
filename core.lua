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

-- a rounding function
local function round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

-- shared variables
local dmg_table = {}
local view_dmg_all = { }
local view_dps_all = { }
local playerClasses = {}

-- default config
local config = {
  -- size
  width = 180,
  height = 17,
  bars = 8,

  -- tracking
  track_all_units = 0,

  -- appearance
  visible = 1,
  texture = 2,
  pfui = 1,

  -- window
  view = 1,
}

-- create core component frames
local window = CreateFrame("Frame", "ShaguDPSWindow", UIParent)
local settings = CreateFrame("Frame")
local parser = CreateFrame("Frame")

-- make everything public
ShaguDPS.textures = textures
ShaguDPS.dmg_table = dmg_table
ShaguDPS.view_dmg_all = view_dmg_all
ShaguDPS.view_dps_all = view_dps_all
ShaguDPS.playerClasses = playerClasses
ShaguDPS.config = config
ShaguDPS.window = window
ShaguDPS.settings = settings
ShaguDPS.parser = parser
ShaguDPS.round = round
