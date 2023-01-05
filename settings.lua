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
  
  if config.borders == 0 then
	window.border:Hide()
	window:SetBackdrop(nil)
  else
	window.border:Show()
	window:SetBackdrop({
	  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	  tile = true, tileSize = 16, edgeSize = 16,
	  insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	window:SetBackdropColor(.5,.5,.5,.5)
	end
	
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
    p("  /sdps spacing " .. config.spacing .. " |cffcccccc- Bar spacing")
    p("  /sdps bars " .. config.bars .. " |cffcccccc- Visible Bars")
    p("  /sdps trackall " .. config.track_all_units .. " |cffcccccc- Track all nearby units")
    p("  /sdps mergepet " .. config.merge_pets .. " |cffcccccc- Merge pets into owner data")
	p("  /sdps borders " .. config.borders .. " |cffcccccc- Visible Borders")
    p("  /sdps texture " .. config.texture .. " |cffcccccc- Set the statusbar texture")
    p("  /sdps pastel " .. config.pastel .. " |cffcccccc- Use pastel colors")
    p("  /sdps toggle |cffcccccc- Toggle window")
    return
  end

  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

  if strlower(cmd) == "visible" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.visible = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)
      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible: " .. config.visible)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "toggle" then
    config.visible = config.visible == 1 and 0 or 1
    ShaguDPS_Config = config
    window.Refresh(true)
    p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible: " .. config.visible)
  elseif strlower(cmd) == "width" then
    if tonumber(args) then
      config.width = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar width: " .. config.width)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "height" then
    if tonumber(args) then
      config.height = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar height: " .. config.height)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "spacing" then
    if tonumber(args) then
      config.spacing = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Bar spacing: " .. config.spacing)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-" .. config.height)
    end
  elseif strlower(cmd) == "bars" then
    if tonumber(args) then
      config.bars = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Visible Bars: " .. config.bars)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-999")
    end
  elseif strlower(cmd) == "trackall" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.track_all_units = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Track all units: " .. config.track_all_units)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "mergepet" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.merge_pets = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Merge pet: " .. config.merge_pets)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "texture" then
    if tonumber(args) and textures[tonumber(args)] then
      config.texture = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Texture: " .. config.texture)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 1-" .. table.getn(textures))
    end
  elseif strlower(cmd) == "pastel" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.pastel = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Use pastel colors: " .. config.pastel)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  elseif strlower(cmd) == "borders" then
    config.borders = config.borders == 1 and 0 or 1
    ShaguDPS_Config = config
	if config.borders == 0 then
		window.border:Hide()
		window:SetBackdrop(nil)
	else
		window.border:Show()
		window:SetBackdrop({
		  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		  tile = true, tileSize = 16, edgeSize = 16,
		  insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		window:SetBackdropColor(.5,.5,.5,.5)
	end
    p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Borders: " .. config.borders)
  end
end
