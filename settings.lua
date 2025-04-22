-- load public variables into local
local settings = ShaguDPS.settings
local window = ShaguDPS.window
local parser = ShaguDPS.parser

local config = ShaguDPS.config
local textures = ShaguDPS.textures
local playerClasses = ShaguDPS.playerClasses

-- default backdrops
local backdrop = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local backdrop_window = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local backdrop_border = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function CreateSelector(self, values)
  local input = CreateFrame("Frame", nil, self)
  input.values = values

  input:Hide()
  input:SetHeight(18)
  input:SetWidth(values and 112 or 54)
  input:SetPoint("TOPRIGHT", self, "TOPRIGHT", -8, -self.entries*18 - 4)
  input:SetBackdrop(backdrop)
  input:SetBackdropColor(.2,.2,.2,1)
  input:SetBackdropBorderColor(.4,.4,.4,1)
  input:SetScript("OnShow", function() input:change() end)

  input.texture = input:CreateTexture()
  input.texture:SetPoint("TOPLEFT", input, "TOPLEFT", 13, -3)
  input.texture:SetPoint("BOTTOMRIGHT", input, "BOTTOMRIGHT", -13, 3)
  input.texture:SetVertexColor(.8, .4, .2)

  input.caption = input:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  input.caption:SetFont(STANDARD_TEXT_FONT, 10)
  input.caption:SetText("Select")
  input.caption:SetAllPoints()

  input.left = CreateFrame("Button", nil, input)
  input.left:SetPoint("LEFT", input, "LEFT", 1, 0)
  input.left:SetWidth(12)
  input.left:SetHeight(16)
  input.left:SetBackdrop(backdrop)
  input.left:SetBackdropColor(.2,.2,.2,1)
  input.left:SetBackdropBorderColor(.4,.4,.4,1)
  input.left:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
  input.left:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
  input.left:SetScript("OnClick", function() input:change(-1) end)
  input.left.caption = input.left:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  input.left.caption:SetFont(STANDARD_TEXT_FONT, 10)
  input.left.caption:SetText("<")
  input.left.caption:SetAllPoints()

  input.right = CreateFrame("Button", nil, input)
  input.right:SetPoint("RIGHT", input, "RIGHT", -1, 0)
  input.right:SetWidth(12)
  input.right:SetHeight(16)
  input.right:SetBackdrop(backdrop)
  input.right:SetBackdropColor(.2,.2,.2,1)
  input.right:SetBackdropBorderColor(.4,.4,.4,1)
  input.right:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
  input.right:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
  input.right:SetScript("OnClick", function() input:change(1) end)
  input.right.caption = input.right:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  input.right.caption:SetFont(STANDARD_TEXT_FONT, 10)
  input.right.caption:SetText(">")
  input.right.caption:SetAllPoints()

  input.change = function(self, mod)
    local id = config[self.entry] or 1

    if mod and self.values and self.values[id + mod] then
      config[self.entry] = math.ceil(config[self.entry] + mod)
    elseif mod and not values then
      config[self.entry] = math.ceil(config[self.entry] + mod)
    end

    if self.values and self.values[config[self.entry]] then
      local _, _, clean = string.find(self.values[config[self.entry]], ".+\\(.+)")
      self.caption:SetText(clean)
    else
      self.caption:SetText(config[self.entry])
    end

    if self.values and not self.values[config[self.entry]+1] then
      self.right:SetAlpha(0.25)
    else
      self.right:SetAlpha(1.00)
    end

    if self.values and not self.values[config[self.entry]-1] then
      self.left:SetAlpha(0.25)
    else
      self.left:SetAlpha(1.00)
    end

    window.Refresh(true)

    -- todo
    if self.entry == "texture" then
      local texture = ShaguDPS.textures[config[self.entry]]
      if texture then
        self.texture:SetTexture(texture)
      else
        self.texture:SetTexture()
      end
    end
  end

  return input
end

local function CreateConfig(self, caption, entry, check)
  self.entries = self.entries and self.entries + 1 or 1

  local entry = entry
  local text = self:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  text:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -self.entries*18 - 4)
  text:SetWidth(100)
  text:SetHeight(18)
  text:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  text:SetJustifyH("LEFT")
  text:SetText(caption)

  if check == "header" then
    text:SetPoint("TOPLEFT", self, "TOPLEFT", 8, -self.entries*18 - 8)
    text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    text:SetTextColor(1, .8, 0)
  end

  if check == "boolean" then
    local input = CreateFrame("CheckButton", nil, self, "OptionsCheckButtonTemplate")
    input:Hide()
    input:SetHeight(18)
    input:SetWidth(18)
    input:SetPoint("TOPRIGHT", self, "TOPRIGHT", -8, -self.entries*18 - 8)
    input:SetScript("OnShow", function()
      this:SetChecked(config[entry] == 1)
    end)

    input:SetScript("OnClick", function()
      config[entry] = this:GetChecked() and 1 or 0
      window.Refresh(true)
    end)

    input:Show()
  end

  if check == "number" or type(check) == "table" then
    local values = type(check) == "table" and check or nil
    local input = self:CreateSelector(values)
    input.entry = entry
    input:Show()
  end
end


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

settings:Hide()
settings:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
settings:SetWidth(192)
settings:SetHeight(216)
settings:SetMovable(true)
settings:EnableMouse(true)
settings:RegisterForDrag("LeftButton")
settings:SetScript("OnDragStart", function() this:StartMoving() end)
settings:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
settings:SetFrameStrata("DIALOG")
settings.CreateConfig = CreateConfig
settings.CreateSelector = CreateSelector

-- window background
settings:SetBackdrop(backdrop_window)
settings:SetBackdropColor(.5,.5,.5,.9)

-- window border
settings.border = CreateFrame("Frame", nil, settings)
settings.border:ClearAllPoints()
settings.border:SetPoint("TOPLEFT", settings, "TOPLEFT", -1,1)
settings.border:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", 1,-1)
settings.border:SetFrameLevel(100)
settings.border:SetBackdrop(backdrop_border)
settings.border:SetBackdropBorderColor(.7,.7,.7,1)

settings.title = settings:CreateTexture(nil, "NORMAL")
settings.title:SetTexture(0,0,0,.6)
settings.title:SetHeight(20)
settings.title:SetPoint("TOPLEFT", 2, -2)
settings.title:SetPoint("TOPRIGHT", -2, -2)

settings.caption = settings:CreateFontString(nil, "OVERLAY", "GameFontWhite")
settings.caption:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
settings.caption:SetText("|cffffcc00Shagu|cffffffffDPS")
settings.caption:SetAllPoints(settings.title)

settings.btnClose = CreateFrame("Button", nil, settings)
settings.btnClose:SetPoint("RIGHT", settings.title, "RIGHT", -4, 0)
settings.btnClose:SetHeight(16)
settings.btnClose:SetWidth(16)
settings.btnClose:SetBackdrop(backdrop)
settings.btnClose:SetBackdropColor(.2,.2,.2,1)
settings.btnClose:SetBackdropBorderColor(.4,.4,.4,1)

settings.btnClose.caption = settings.btnClose:CreateFontString(nil, "OVERLAY", "GameFontWhite")
settings.btnClose.caption:SetFont(STANDARD_TEXT_FONT, 14)
settings.btnClose.caption:SetText("x")
settings.btnClose.caption:SetAllPoints()
settings.btnClose:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
settings.btnClose:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
settings.btnClose:SetScript("OnClick", function() settings:Hide() end)

settings:CreateConfig("Parser", nil, "header")
settings:CreateConfig("Track All Nearby Units", "track_all_units", "boolean")
settings:CreateConfig("Merge Pets With Owner", "merge_pets", "boolean")

settings:CreateConfig("Window", nil, "header")
settings:CreateConfig("Bar Texture", "texture", ShaguDPS.textures)
settings:CreateConfig("Bar Height", "height", "number")
settings:CreateConfig("Bar Spacing", "spacing", "number")
settings:CreateConfig("Pastel Colors", "pastel", "boolean")
settings:CreateConfig("Show Backdrops", "backdrop", "boolean")
settings:CreateConfig("Lock Windows", "lock", "boolean")

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
    p("  /sdps texture " .. config.texture .. " |cffcccccc- Set the statusbar texture")
    p("  /sdps pastel " .. config.pastel .. " |cffcccccc- Use pastel colors")
    p("  /sdps backdrop " .. config.backdrop .. " |cffcccccc- Show window backdrop and border")
    p("  /sdps lock " .. config.lock .. " |cffcccccc- Lock window")
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
  elseif strlower(cmd) == "lock" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.lock = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)
      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Lock: " .. config.lock)
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
  elseif strlower(cmd) == "backdrop" then
    if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
      config.backdrop = tonumber(args)
      ShaguDPS_Config = config
      window.Refresh(true)

      p("|cffffcc00Shagu|cffffffffDPS:|cffffddcc Show window backdrop: " .. config.backdrop)
    else
      p("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are 0-1")
    end
  end
end
