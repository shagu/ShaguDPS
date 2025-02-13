-- load public variables into local
local settings = ShaguDPS.settings
local window = ShaguDPS.window
local parser = ShaguDPS.parser

local config = ShaguDPS.config
local configMain = ShaguDPS.config.window_one
local configAlt = ShaguDPS.config.window_two
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
  ShaguDPS:RefreshAll(true)
end)

-- Provide Slash Commands
SLASH_SHAGUMETER1, SLASH_SHAGUMETER2, SLASH_SHAGUMETER3 = "/shagudps", "/sdps", "/sd"
SlashCmdList["SHAGUMETER"] = function(msg, editbox)

  local function p(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  end

  if (msg == "" or msg == nil) then
    p("|cffffcc00Shagu|cffffffffDPS:")
    p("  /sdps visible " .. configMain.visible .. " |cffcccccc- Show main window")
    p("  /sdps width " .. configMain.width .. " |cffcccccc- Bar width")
    p("  /sdps height " .. configMain.height .. " |cffcccccc- Bar height")
    p("  /sdps spacing " .. configMain.spacing .. " |cffcccccc- Bar spacing")
    p("  /sdps bars " .. configMain.bars .. " |cffcccccc- Visible Bars")
    p("  /sdps trackall " .. configMain.track_all_units .. " |cffcccccc- Track all nearby units")
    p("  /sdps mergepet " .. configMain.merge_pets .. " |cffcccccc- Merge pets into owner data")
    p("  /sdps texture " .. configMain.texture .. " |cffcccccc- Set the statusbar texture")
    p("  /sdps pastel " .. configMain.pastel .. " |cffcccccc- Use pastel colors")
    p("  /sdps backdrop " .. configMain.backdrop .. " |cffcccccc- Show window backdrop and border")
    p("  /sdps lock " .. configMain.lock .. " |cffcccccc- Lock window")
    p("  /sdps toggle |cffcccccc- Toggle window")
    return
  end

  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

  if strlower(cmd) == "visible" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      configMain.visible = tonumber(args)
      configAlt.visible = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)
      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible: " .. configMain.visible)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "lock" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      configMain.lock = tonumber(args)
      configAlt.lock = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)
      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Lock: " .. configMain.lock)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "toggle" then
    configMain.visible = configMain.visible == 1 and 0 or 1
    configAlt.visible = configAlt.visible == 1 or 0 or 1
    ShaguDPS_Config = config
    ShaguDPS:RefreshAll(true)
    p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible: " .. configMain.visible)
  elseif strlower(cmd) == "width" then
    if tonumber(args) then
      configMain.width = tonumber(args)
      configAlt.width = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar width: " .. configMain.width)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "height" then
    if tonumber(args) then
      configMain.height = tonumber(args)
      configAlt.height = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar height: " .. configMain.height)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "spacing" then
    if tonumber(args) then
      configMain.spacing = tonumber(args)
      configAlt.spacing = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar spacing: " .. configMain.spacing)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-" .. configMain.height)
    end
  elseif strlower(cmd) == "bars" then
    if tonumber(args) then
      configMain.bars = tonumber(args)
      configAlt.bars = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible Bars: " .. configMain.bars)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "trackall" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      configMain.track_all_units = tonumber(args)
      configAlt.track_all_units = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Track all units: " .. configMain.track_all_units)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "mergepet" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      configMain.merge_pets = tonumber(args)
      configAlt.merge_pets = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Merge pet: " .. configMain.merge_pets)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "texture" then
    if tonumber(args) and textures[tonumber(args)] then
      configMain.texture = tonumber(args)
      configAlt.texture = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Texture: " .. configMain.texture)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-" .. table.getn(textures))
    end
  elseif strlower(cmd) == "pastel" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      configMain.pastel = tonumber(args)
      configAlt.pastel = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Use pastel colors: " .. configMain.pastel)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "backdrop" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      configMain.backdrop = tonumber(args)
      configAlt.backdrop = tonumber(args)
      ShaguDPS_Config = config
      ShaguDPS:RefreshAll(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Show window backdrop: " .. configMain.backdrop)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  end
end
