ShaguMeter = {}

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

-- shared variables
local dmg_table = {}
local view_dmg_all = { }
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
}

-- create core component frames
local window = CreateFrame("Frame", "ShaguMeterWindow", UIParent)
local settings = CreateFrame("Frame")
local parser = CreateFrame("Frame")

-- make everything public
ShaguMeter.textures = textures
ShaguMeter.dmg_table = dmg_table
ShaguMeter.view_dmg_all = view_dmg_all
ShaguMeter.playerClasses = playerClasses
ShaguMeter.config = config
ShaguMeter.window = window
ShaguMeter.settings = settings
ShaguMeter.parser = parser