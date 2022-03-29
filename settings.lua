-- load public variables into local
local settings = ShaguMeter.settings
local window = ShaguMeter.window
local parser = ShaguMeter.parser

local config = ShaguMeter.config
local textures = ShaguMeter.textures
local playerClasses = ShaguMeter.playerClasses

-- Load settings on Login
settings:RegisterEvent("PLAYER_ENTERING_WORLD")
settings:SetScript("OnEvent", function()
  if ShaguMeter_Config then
    for k, v in pairs(ShaguMeter_Config) do
      -- print(k .. " -> " .. v)
      config[k] = v
    end
  end

  ShaguMeter_Config = config
  window.Refresh(true)
end)

-- Provide Slash Commands
SLASH_SHAGUMETER1, SLASH_SHAGUMETER2, SLASH_SHAGUMETER3 = "/shagumeter", "/meter", "/sm"
SlashCmdList["SHAGUMETER"] = function(msg, editbox)

  local function p(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  end

  if (msg == "" or msg == nil) then
    p("|cffffcc00Shagu|cffffffffMeter:")
    p("  /sm visible " .. config.visible .. " |cffcccccc- Show main window")
    p("  /sm width " .. config.width .. " |cffcccccc- Bar width")
    p("  /sm height " .. config.height .. " |cffcccccc- Bar height")
    p("  /sm bars " .. config.bars .. " |cffcccccc- Visible Bars")
    p("  /sm trackall " .. config.track_all_units .. " |cffcccccc- Track all nearby units")
    p("  /sm texture " .. config.texture .. " |cffcccccc- Set the statusbar texture")
    p("  /sm pfui " .. config.pfui .. " |cffcccccc- Inherit pfUI theme")
    p("  /sm toggle |cffcccccc- Toggle window")
    return
  end

  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

  if strlower(cmd) == "visible" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.visible = tonumber(args)
      ShaguMeter_Config = config
      window:Refresh(true)
      p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Visible: " .. config.visible)
    else
      p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "toggle" then
    config.visible = config.visible == 1 and 0 or 1
    ShaguMeter_Config = config
    window:Refresh(true)
    p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Visible: " .. config.visible)
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
      ShaguMeter_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Bar width: " .. config.width)
    else
      p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "height" then
    if tonumber(args) then
      config.height = tonumber(args)
      ShaguMeter_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Bar height: " .. config.height)
    else
      p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "bars" then
    if tonumber(args) then
      config.bars = tonumber(args)
      ShaguMeter_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Visible Bars: " .. config.bars)
    else
      p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "trackall" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.track_all_units = tonumber(args)
      ShaguMeter_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Track all units: " .. config.track_all_units)
    else
      p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "texture" then
    if tonumber(args) and textures[tonumber(args)] then
      config.texture = tonumber(args)
      ShaguMeter_Config = config
      window:Refresh(true)

      p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Texture: " .. config.texture)
    else
      p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-" .. table.getn(textures))
    end
  elseif strlower(cmd) == "pfui" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.pfui = tonumber(args)
      ShaguMeter_Config = config
      window:Refresh(true)
      p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc pfUI theme: " .. config.pfui)
    else
      p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 0-1")
    end
  end
end
