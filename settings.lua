-- load public variables into local
local settings = ShaguDPS.settings
local window = ShaguDPS.window
local parser = ShaguDPS.parser

local config = ShaguDPS.config
local textures = ShaguDPS.textures
local playerClasses = ShaguDPS.playerClasses

-- Load settings on Login
settings:RegisterEvent("PLAYER_ENTERING_WORLD")
settings:SetScript("OnEvent", function()
  if ShaguDPS_Config then
    for k, v in pairs(ShaguDPS_Config) do
      config[k] = v
    end
  end

  ShaguDPS_Config = config
  window.Refresh(true)
end)

-- Provide Slash Commands
SLASH_SHAGUMETER1, SLASH_SHAGUMETER2, SLASH_SHAGUMETER3 = "/shagudps", "/sdps", "/sd"
SlashCmdList["SHAGUMETER"] = function(msg, editbox)

  local function p(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  end

  if (msg == "" or msg == nil) then
    p("|cffffcc00Shagu|cffffffffDPS:")
    p("  /sdps visible " .. config.visible .. " |cffcccccc- Show main window")
    p("  /sdps width " .. config.width .. " |cffcccccc- Bar width")
    p("  /sdps height " .. config.height .. " |cffcccccc- Bar height")
    p("  /sdps bars " .. config.bars .. " |cffcccccc- Visible Bars")
    p("  /sdps trackall " .. config.track_all_units .. " |cffcccccc- Track all nearby units")
    p("  /sdps texture " .. config.texture .. " |cffcccccc- Set the statusbar texture")
    p("  /sdps pfui " .. config.pfui .. " |cffcccccc- Inherit pfUI theme")
    p("  /sdps toggle |cffcccccc- Toggle window")
    return
  end

  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

  if strlower(cmd) == "visible" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.visible = tonumber(args)
      ShaguDPS_Config = config
      window:Refresh(true)
      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible: " .. config.visible)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "toggle" then
    config.visible = config.visible == 1 and 0 or 1
    ShaguDPS_Config = config
    window:Refresh(true)
    p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible: " .. config.visible)
  elseif strlower(cmd) == "debug" then
    playerClasses["Test1"] = "WARRIOR"
    playerClasses["Test2"] = "WARLOCK"
    playerClasses["Test3"] = "HUNTER"
    playerClasses["Test4"] = "PRIEST"
    playerClasses["Test5"] = "DRUID"
    playerClasses["Test6"] = "SHAMAN"
    playerClasses["Test7"] = "PALADIN"
    playerClasses["Test8"] = "ROGUE"
    playerClasses["Test9"] = "DRUID"

    local count = 1
    for source, v in pairs(playerClasses) do
      count = count + 1
      for i = 0, 20 do
        parser:AddData(source, "Auto Hit", UnitName("player"), floor(math.random()*50*count), "physical", true)
        parser:AddData(source, "Aimed Shot", UnitName("player"), floor(math.random()*20*count), "physical", true)
        parser:AddData(source, "Multishot", UnitName("player"), floor(math.random()*20*count), "physical", true)
      end
    end

  elseif strlower(cmd) == "width" then
    if tonumber(args) then
      config.width = tonumber(args)
      ShaguDPS_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar width: " .. config.width)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "height" then
    if tonumber(args) then
      config.height = tonumber(args)
      ShaguDPS_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar height: " .. config.height)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "bars" then
    if tonumber(args) then
      config.bars = tonumber(args)
      ShaguDPS_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible Bars: " .. config.bars)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "trackall" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.track_all_units = tonumber(args)
      ShaguDPS_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Track all units: " .. config.track_all_units)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "texture" then
    if tonumber(args) and textures[tonumber(args)] then
      config.texture = tonumber(args)
      ShaguDPS_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Texture: " .. config.texture)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-" .. table.getn(textures))
    end
  elseif strlower(cmd) == "pfui" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.pfui = tonumber(args)
      ShaguDPS_Config = config
      window:Refresh(true)
      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc pfUI theme: " .. config.pfui)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  end
end
