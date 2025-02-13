-- check for expansion
local tbc = ShaguDPS.expansion() == "tbc" and true or nil

-- load public variables into local
local window = ShaguDPS.window
local parser = ShaguDPS.parser

local data = ShaguDPS.data
local config = ShaguDPS.config
local internals = ShaguDPS.internals

local textures = ShaguDPS.textures
local spairs = ShaguDPS.spairs
local round = ShaguDPS.round

local scroll = 0
local segment = data.damage[0]

-- all known classes
local classes = {
  WARRIOR = true,
  MAGE = true,
  ROGUE = true,
  DRUID = true,
  HUNTER = true,
  SHAMAN = true,
  PRIEST = true,
  WARLOCK = true,
  PALADIN = true,
}

-- default backdrops
local backdrop = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local backdrop_window = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local backdrop_border = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- templates describing the window contents
local view_templates = {
  [1] = { -- damage
    name = "Damage",
    sort = "normal",
    bar_max = "best",
    bar_val = "value",
    bar_lower_max = nil,
    bar_lower_val = nil,
    chat_string = "%s (%.1f%%)",
    bar_string = "%s (%.1f%%)",
    bar_string_params = { "value", "percent" },
  },
  [2] = { -- dps
    name = "DPS",
    sort = "per_second",
    bar_max = "persecond_best",
    bar_val = "value_persecond",
    bar_lower_max = nil,
    bar_lower_val = nil,
    chat_string = "%s (%.1f%%)",
    bar_string = "%s (%.1f%%)",
    bar_string_params = { "value_persecond", "percent_persecond" },
  },
  [3] = { -- heal
    name = "Heal",
    sort = "normal",
    bar_max = "best",
    bar_val = "effective_value",
    bar_lower_max = "best",
    bar_lower_val = "value",
    chat_string = "[+%s] %s (%.1f%%)",
    bar_string = "|cffcc8888+%s|r %s (%.1f%%)",
    bar_string_params = { "uneffective_value", "effective_value", "effective_percent" },
  },
  [4] = { -- hps
    name = "HPS",
    sort = "per_second",
    bar_max = "persecond_best",
    bar_val = "effective_value_persecond",
    bar_lower_max = "persecond_best",
    bar_lower_val = "value_persecond",
    chat_string = "[+%s] %s (%.1f%%)",
    bar_string = "|cffcc8888+%s|r %s (%.1f%%)",
    bar_string_params = { "uneffective_value_persecond", "effective_value_persecond", "effective_percent" },
  },
}

-- panel button templates
local menubuttons = {
  -- segments
  ["Current"] = { 0, 1, -25.5, "Current Segment", "|cffffffffShow current fight", "segment" },
  ["Overall"] = { 1, 0, -25.5, "Overall Segment", "|cffffffffShow all fights", "segment" },

  -- modes
  ["Damage"]  = { 0, 1, 25.5, "Damage View", "|cffffffffShow Damage Done", "view" },
  ["DPS"]     = { 1, 2, 25.5, "DPS View", "|cffffffffShow Damage Per Second", "view" },
  ["Heal"]    = { 2, 3, 25.5, "Heal View", "|cffffffffShow Healing Done", "view" },
  ["HPS"]     = { 3, 4, 25.5, "HPS View", "|cffffffffShow Heal Per Second", "view" },
}

-- default colors of chat types
local chatcolors = {
  ["SAY"] = "|cffFFFFFF",
  ["EMOTE"] = "|cffFF7E40",
  ["YELL"] = "|cffFF3F40",
  ["PARTY"] = "|cffAAABFE",
  ["GUILD"] = "|cff3CE13F",
  ["OFFICER"] = "|cff40BC40",
  ["RAID"] = "|cffFF7D01",
  ["RAID_WARNING"] = "|cffFF4700",
  ["BATTLEGROUND"] = "|cffFF7D01",
  ["WHISPER"] = "|cffFF7EFF",
  ["CHANNEL"] = "|cffFEC1C0"
}

local sort_algorithms = {
  normal = function(t, a, b)
    if t[a]["_esum"] and t[b]["_esum"] and t[a]["_esum"] ~= t[b]["_esum"] then
      return t[b]["_esum"] < t[a]["_esum"]
    else
      return t[b]["_sum"] < t[a]["_sum"]
    end
  end,
  per_second = function(t, a, b)
    if t[a]["_esum"] and t[b]["_esum"] and t[a]["_esum"] ~= t[b]["_esum"] then
      return t[b]["_esum"] / t[b]["_ctime"] < t[a]["_esum"] / t[a]["_ctime"]
    else
      return t[b]["_sum"] / t[b]["_ctime"] < t[a]["_sum"] / t[a]["_ctime"]
    end
  end,
  single_spell = function(t, a, b)
    if t["_effective"] and t["_effective"][a] and t["_effective"][b] and t["_effective"][a] ~= t["_effective"][b] then
      return t["_effective"][b] < t["_effective"][a]
    else
      if tonumber(t[b]) and tonumber(t[a]) then return t[b] < t[a] end
    end
  end
}

local rgbcache = {}
local function str2rgb(text)
  if not text then return 1, 1, 1 end
  if rgbcache[text] then return unpack(rgbcache[text]) end
  local counter = 1
  local l = string.len(text)
  for i = 1, l, 3 do
    counter = mod(counter * 8161, 4294967279) +
        (string.byte(text, i) * 16776193) +
        ((string.byte(text, i + 1) or (l - i + 256)) * 8372226) +
        ((string.byte(text, i + 2) or (l - i + 256)) * 3932164)
  end
  local hash = mod(mod(counter, 4294967291), 16777216)
  local r = (hash - (mod(hash, 65536))) / 65536
  local g = ((hash - r * 65536) - (mod((hash - r * 65536), 256))) / 256
  local b = hash - r * 65536 - g * 256
  rgbcache[text] = { r / 255, g / 255, b / 255 }
  return unpack(rgbcache[text])
end

local function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[table.getn(keys) + 1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a, b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

local function ResetData()
  -- clear overall damage data
  for k, v in pairs(data.damage[0]) do
    data.damage[0][k] = nil
  end

  -- clear current damage data
  for k, v in pairs(data.damage[1]) do
    data.damage[1][k] = nil
  end

  -- clear overall heal data
  for k, v in pairs(data.heal[0]) do
    data.heal[0][k] = nil
  end

  -- clear current heal data
  for k, v in pairs(data.heal[1]) do
    data.heal[1][k] = nil
  end

  -- reset scroll and reload
  scroll = 0
  ShaguDPS:RefreshAll()
end

local function barTooltipShow()
  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")

  local value = segment[this.unit]["_sum"]
  local persec = round(segment[this.unit]["_sum"] / segment[this.unit]["_ctime"], 1)

  GameTooltip:AddLine(this.title .. ":")

  if config.view == 1 or config.view == 2 then
    GameTooltip:AddDoubleLine("|cffffffffDamage", "|cffffffff" .. value)
    GameTooltip:AddDoubleLine("|cffffffffDamage Per Second", "|cffffffff" .. persec)
  elseif config.view == 3 or config.view == 4 then
    local evalue = segment[this.unit]["_esum"]
    local epersec = round(segment[this.unit]["_esum"] / segment[this.unit]["_ctime"], 1)

    GameTooltip:AddDoubleLine("|cffffffffHealing", "|cffffffff" .. evalue)
    GameTooltip:AddDoubleLine("|cffaaaaaaOverheal", "|cffcc8888+" .. value - evalue)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("|cffffffffHealing Per Second", "|cffffffff" .. epersec)
    GameTooltip:AddDoubleLine("|cffaaaaaaOverheal Per Second", "|cffcc8888+" .. persec - epersec)
  end

  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Details:")

  for attack, damage in spairs(segment[this.unit], sort_algorithms.single_spell) do
    if attack and not internals[attack] then
      local percent = damage == 0 and 0 or round(damage / segment[this.unit]["_sum"] * 100, 1)
      if segment[this.unit]["_effective"] and segment[this.unit]["_effective"][attack] then
        -- heal / effective heal
        local effective = segment[this.unit]["_effective"][attack]
        local epercent = effective == 0 and 0 or round(effective / segment[this.unit]["_esum"] * 100, 1)

        local str = string.format("|cffcc8888+%s|cffffffff %s (%.1f%%)", damage - effective, effective, epercent)
        GameTooltip:AddDoubleLine("|cffffffff" .. attack, str)
      else
        -- damage
        local str = string.format("|cffffffff %s (%.1f%%)", damage, percent)
        GameTooltip:AddDoubleLine("|cffffffff" .. attack, str)
      end
    end
  end
  GameTooltip:Show()
end

local function barTooltipHide()
  GameTooltip:Hide()
end

local function barScrollWheel()
  scroll = arg1 > 0 and scroll - 1 or scroll
  scroll = arg1 < 0 and scroll + 1 or scroll

  local count = 0
  for k, v in pairs(segment) do
    count = count + 1
  end

  scroll = math.min(scroll, count + 1 - config.bars)
  scroll = math.max(scroll, 0)

  ShaguDPS:RefreshAll()
end

local function btnEnter()
  if this.tooltip then
    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    for i, data in pairs(this.tooltip) do
      if type(data) == "string" then
        GameTooltip:AddLine(data)
      elseif type(data) == "table" then
        GameTooltip:AddDoubleLine(data[1], data[2])
      end
    end
    GameTooltip:Show()
  end

  this:SetBackdropBorderColor(1, .9, 0, 1)
end

local function btnLeave()
  if this.tooltip then
    GameTooltip:Hide()
  end

  this:SetBackdropBorderColor(.4, .4, .4, 1)
end

local function announce(text)
  local type = tbc and ChatFrameEditBox:GetAttribute("chatType") or ChatFrameEditBox.chatType
  local language = tbc and ChatFrameEditBox:GetAttribute("language") or ChatFrameEditBox.language
  local channel = tbc and ChatFrameEditBox:GetAttribute("channelTarget") or ChatFrameEditBox.channelTarget
  local target = tbc and ChatFrameEditBox:GetAttribute("tellTarget") or ChatFrameEditBox.tellTarget

  if type == "WHISPER" then
    SendChatMessage(text, type, language, target)
  elseif type == "CHANNEL" then
    SendChatMessage(text, type, language, channel);
  else
    SendChatMessage(text, type, language);
  end
end

local function CreateBar(parent, i, background)
  parent.bars[i] = parent.bars[i] or CreateFrame("StatusBar", "ShaguDPSBar" .. i, parent)
  parent.bars[i]:SetStatusBarTexture(textures[config.texture] or textures[1])
  parent.bars[i]:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -config.height * (i - 1) - 22)
  parent.bars[i]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -config.height * (i - 1) - 22)
  parent.bars[i]:SetHeight(config.height - config.spacing)
  parent.bars[i]:SetFrameLevel(4)

  parent.bars[i].lowerBar = parent.bars[i].lowerBar or CreateFrame("StatusBar", "ShaguDPSLowerBar" .. i, parent)
  parent.bars[i].lowerBar:SetStatusBarTexture(textures[config.texture] or textures[1])
  parent.bars[i].lowerBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -config.height * (i - 1) - 22)
  parent.bars[i].lowerBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -config.height * (i - 1) - 22)
  parent.bars[i].lowerBar:SetStatusBarColor(1, 1, 1, .4)
  parent.bars[i].lowerBar:SetHeight(config.height - config.spacing)
  parent.bars[i].lowerBar:SetFrameLevel(2)

  parent.bars[i].textLeft = parent.bars[i].textLeft or
      parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
  parent.bars[i].textLeft:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  parent.bars[i].textLeft:SetJustifyH("LEFT")
  parent.bars[i].textLeft:SetFontObject(GameFontWhite)
  parent.bars[i].textLeft:SetParent(parent.bars[i])
  parent.bars[i].textLeft:ClearAllPoints()
  parent.bars[i].textLeft:SetPoint("TOPLEFT", parent.bars[i], "TOPLEFT", 5, 1)
  parent.bars[i].textLeft:SetPoint("BOTTOMRIGHT", parent.bars[i], "BOTTOMRIGHT", -5, 0)

  parent.bars[i].textRight = parent.bars[i].textRight or
      parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
  parent.bars[i].textRight:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  parent.bars[i].textRight:SetJustifyH("RIGHT")
  parent.bars[i].textRight:SetFontObject(GameFontWhite)
  parent.bars[i].textRight:SetParent(parent.bars[i])
  parent.bars[i].textRight:ClearAllPoints()
  parent.bars[i].textRight:SetPoint("TOPLEFT", parent.bars[i], "TOPLEFT", 5, 1)
  parent.bars[i].textRight:SetPoint("BOTTOMRIGHT", parent.bars[i], "BOTTOMRIGHT", -5, 0)

  parent.bars[i]:EnableMouse(true)
  parent.bars[i]:SetScript("OnEnter", barTooltipShow)
  parent.bars[i]:SetScript("OnLeave", barTooltipHide)

  return parent.bars[i]
end

function ShaguDPS:CreateMeterWindow(database, id)
  --config.windowID
  local name = (id == 1) and "ShaguDPSWindow" or ("ShaguDPSWindow"..id)
  local meter = CreateFrame("Frame", name, UIParent)
  meter:ClearAllPoints()
  meter:SetWidth(database.width)
  meter:SetHeight(database.height * database.bars + 22 + 4)
  meter:EnableMouse(true)
  meter:SetMovable(true)
  meter:EnableMouseWheel(true)
  --meter:SetUserPlaced(true)
  meter:SetClampedToScreen(true)
  meter:RegisterForDrag("LeftButton")
  meter:SetScript("OnDragStart", function() if database.lock == 0 then meter:StartMoving() end end)
  meter:SetScript("OnDragStop", function() meter:StopMovingOrSizing() end)
  meter:SetScript("OnMouseWheel", barScrollWheel)
  meter:SetScript("OnShow", function() meter.Refresh(true) end)
  meter:SetScript("OnUpdate", function()
    if (meter.tick or 1) > GetTime() then return else meter.tick = GetTime() + 0.2 end

    if meter.needs_refresh then
      meter.needs_refresh = nil
      meter.Refresh()
    end
  end)
  meter:Hide()

  local title = meter:CreateTexture(nil, "NORMAL")
  title:SetTexture(0, 0, 0, 0.6)
  title:SetHeight(20)
  title:SetPoint("TOPLEFT", 2, -2)
  title:SetPoint("TOPRIGHT", -2, -2)
  meter.title = title

  local btnSegment = CreateFrame("Button", "ShaguDPSDamage" .. id, meter)
  btnSegment:SetPoint("CENTER", meter.title, "CENTER", -30, 0)
  btnSegment:SetFrameStrata("MEDIUM")
  btnSegment:SetHeight(16)
  btnSegment:SetWidth(50)
  btnSegment:SetBackdrop(backdrop)
  btnSegment:SetBackdropColor(.2, .2, .2, 1)
  btnSegment:SetBackdropBorderColor(.4, .4, .4, 1)
  meter.btnSegment = btnSegment

  btnSegment.caption = meter.btnSegment:CreateFontString("ShaguDPSTitle" .. id, "OVERLAY", "GameFontWhite")
  btnSegment.caption:SetFont(STANDARD_TEXT_FONT, 9)
  btnSegment.caption:SetText("Overall")
  btnSegment.caption:SetAllPoints()
  meter.btnSegment.tooltip = { "Select Segment", "|cffffffffOverall, Current" }
  meter.btnSegment:SetScript("OnEnter", btnEnter)
  meter.btnSegment:SetScript("OnLeave", btnLeave)
  meter.btnSegment:SetScript("OnClick", function()
    if meter.btnCurrent:IsShown() then
      meter.btnDamage:Hide()
      meter.btnDPS:Hide()
      meter.btnHeal:Hide()
      meter.btnHPS:Hide()
      meter.btnOverall:Hide()
      meter.btnCurrent:Hide()
    else
      meter.btnDamage:Hide()
      meter.btnDPS:Hide()
      meter.btnHeal:Hide()
      meter.btnHPS:Hide()
      meter.btnOverall:Show()
      meter.btnCurrent:Show()
    end
  end)

  local btnMode = CreateFrame("Button", "ShaguDPSDamageMode" .. id, meter)
  btnMode:SetPoint("CENTER", meter.title, "CENTER", 20, 0)
  btnMode:SetFrameStrata("MEDIUM")
  btnMode:SetHeight(16)
  btnMode:SetWidth(50)
  btnMode:SetBackdrop(backdrop)
  btnMode:SetBackdropColor(.2, .2, .2, 1)
  btnMode:SetBackdropBorderColor(.4, .4, .4, 1)
  meter.btnMode = btnMode

  local caption = meter.btnMode:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
  caption = meter.btnMode:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
  caption:SetFont(STANDARD_TEXT_FONT, 9)
  caption:SetText("Mode: Damage")
  caption:SetAllPoints()
  meter.btnMode.caption = caption
  meter.btnMode.tooltip = { "Select Mode", "|cffffffffDamage, DPS, Heal, HPS" }
  meter.btnMode:SetScript("OnEnter", btnEnter)
  meter.btnMode:SetScript("OnLeave", btnLeave)
  meter.btnMode:SetScript("OnClick", function()
    if meter.btnDamage:IsShown() then
      meter.btnDamage:Hide()
      meter.btnDPS:Hide()
      meter.btnHeal:Hide()
      meter.btnHPS:Hide()
      meter.btnOverall:Hide()
      meter.btnCurrent:Hide()
    else
      meter.btnDamage:Show()
      meter.btnDPS:Show()
      meter.btnHeal:Show()
      meter.btnHPS:Show()
      meter.btnOverall:Hide()
      meter.btnCurrent:Hide()
    end
  end)

  for name, template in pairs(menubuttons) do
    meter["btn" .. name] = CreateFrame("Button", "ShaguDPS" .. name .. id, meter)
    local button = meter["btn" .. name]
    local temp = template

    button:SetPoint("CENTER", meter.title, "CENTER", template[3], -18 - template[1] * 15)
    button:SetFrameStrata("HIGH")
    button:SetHeight(16)
    button:SetWidth(50)
    button:SetBackdrop(backdrop)
    button:SetBackdropColor(.2, .2, .2, 1)
    button:SetBackdropBorderColor(.4, .4, .4, 1)
    button:Hide()

    button.caption = button:CreateFontString("ShaguDPS" .. name .. "Title" .. id, "OVERLAY", "GameFontWhite")
    button.caption:SetFont(STANDARD_TEXT_FONT, 9)
    button.caption:SetText(name)
    button.caption:SetAllPoints()
    button.tooltip = { temp[4], temp[5] }
    button:SetScript("OnEnter", btnEnter)
    button:SetScript("OnLeave", btnLeave)
    button:SetScript("OnClick", function()
      config[temp[6]] = temp[2]

      scroll = 0
      meter.Refresh(true)

      for button in pairs(menubuttons) do
        meter["btn" .. button]:Hide()
      end
    end)
  end

  meter.btnReset = CreateFrame("Button", "ShaguDPSReset" .. id, meter)
  meter.btnReset:SetPoint("RIGHT", meter.title, "RIGHT", -4, 0)
  meter.btnReset:SetFrameStrata("MEDIUM")
  meter.btnReset:SetHeight(16)
  meter.btnReset:SetWidth(16)
  meter.btnReset:SetBackdrop(backdrop)
  meter.btnReset:SetBackdropColor(.2, .2, .2, 1)
  meter.btnReset:SetBackdropBorderColor(.4, .4, .4, 1)
  meter.btnReset.tooltip = {
    "Reset Data",
    { "|cffffffffClick",       "|cffaaaaaaAsk to reset all data." },
    { "|cffffffffShift-Click", "|cffaaaaaaReset all data." },
  }

  meter.btnReset.tex = meter.btnReset:CreateTexture()
  meter.btnReset.tex:SetWidth(10)
  meter.btnReset.tex:SetHeight(10)
  meter.btnReset.tex:SetPoint("CENTER", 0, 0)
  meter.btnReset.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\reset")
  meter.btnReset:SetScript("OnEnter", btnEnter)
  meter.btnReset:SetScript("OnLeave", btnLeave)
  meter.btnReset:SetScript("OnClick", function()
    if IsShiftKeyDown() then
      ResetData()
    else
      local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
      dialog.text = "Do you wish to reset the data?"
      dialog.OnAccept = ResetData
      StaticPopup_Show("SHAGUMETER_QUESTION")
    end
  end)

  if id == 1 then
    meter.btnOpenAlt = CreateFrame("Button", "ShaguDPSAddWindow", meter)
    meter.btnOpenAlt:SetPoint("RIGHT", meter.btnReset, "LEFT", -4, 0)
    meter.btnOpenAlt:SetFrameStrata("MEDIUM")
    meter.btnOpenAlt:SetHeight(16)
    meter.btnOpenAlt:SetWidth(16)
    meter.btnOpenAlt:SetBackdrop(backdrop)
    meter.btnOpenAlt:SetBackdropColor(.2, .2, .2, 1)
    meter.btnOpenAlt:SetBackdropBorderColor(.4, .4, .4, 1)
    meter.btnOpenAlt.tooltip = {
      "Open Second Window",
      { "|cffffffffClick",       "|cffaaaaaaOpen the second data window." },
      { "|cffffffffShift-Click", "|cffaaaaaaClose the second data window." },
    }

    meter.btnOpenAlt.tex = meter.btnOpenAlt:CreateTexture()
    meter.btnOpenAlt.tex:SetWidth(10)
    meter.btnOpenAlt.tex:SetHeight(10)
    meter.btnOpenAlt.tex:SetPoint("CENTER", 0, 0)
    meter.btnOpenAlt.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\reset")
    meter.btnOpenAlt:SetScript("OnEnter", btnEnter)
    meter.btnOpenAlt:SetScript("OnLeave", btnLeave)
    meter.btnOpenAlt:SetScript("OnClick", function()
      if ShaguDPS.Windows[2] then
        if IsShiftKeyDown() then
          meter.btnOpenAlt.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\plus")
          ShaguDPS.Windows[2]:Hide()
            ShaguDPS.config.window_two.visible = 0
        else
          meter.btnOpenAlt.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\minus")
          ShaguDPS.Windows[2]:Show()
            ShaguDPS.config.window_two.visible = 1
        end
      end
    end)
  end

  meter.btnAnnounce = CreateFrame("Button", "ShaguDPSReset" .. id, meter)
  meter.btnAnnounce:SetPoint("LEFT", meter.title, "LEFT", 4, 0)
  meter.btnAnnounce:SetFrameStrata("MEDIUM")
  meter.btnAnnounce:SetHeight(16)
  meter.btnAnnounce:SetWidth(16)
  meter.btnAnnounce:SetBackdrop(backdrop)
  meter.btnAnnounce:SetBackdropColor(.2, .2, .2, 1)
  meter.btnAnnounce:SetBackdropBorderColor(.4, .4, .4, 1)
  meter.btnAnnounce.tooltip = {
    "Send to Chat",
    { "|cffffffffClick",       "|cffaaaaaaAsk to anounce all data." },
    { "|cffffffffShift-Click", "|cffaaaaaaAnnounce all data." },
  }
  meter.btnAnnounce:SetScript("OnEnter", btnEnter)
  meter.btnAnnounce:SetScript("OnLeave", btnLeave)
  meter.btnAnnounce:SetScript("OnClick", function()
    if IsShiftKeyDown() then
      -- reload / anounce
      meter.Refresh(nil, true)
    else
      local ctype = tbc and ChatFrameEditBox:GetAttribute("chatType") or ChatFrameEditBox.chatType
      local color = chatcolors[ctype]
      if not color then color = "|cff00FAF6" end

      local name = view_templates[config.view].name
      local text = "Post |cffffdd00" .. name .. "|r data into /" .. color .. string.lower(ctype) .. "|r?"

      local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
      dialog.text = text

      dialog.OnAccept = function()
        meter.Refresh(nil, true)
      end
      StaticPopup_Show("SHAGUMETER_QUESTION")
    end
  end)

  meter.btnAnnounce.tex = meter.btnAnnounce:CreateTexture()
  meter.btnAnnounce.tex:SetWidth(10)
  meter.btnAnnounce.tex:SetHeight(10)
  meter.btnAnnounce.tex:SetPoint("CENTER", 0, 0)
  meter.btnAnnounce.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\announce")

  meter.border = CreateFrame("Frame", "ShaguDPSBorder" .. id, meter)
  meter.border:ClearAllPoints()
  meter.border:SetPoint("TOPLEFT", meter, "TOPLEFT", -1, 1)
  meter.border:SetPoint("BOTTOMRIGHT", meter, "BOTTOMRIGHT", 1, -1)
  meter.border:SetFrameLevel(100)

  meter.bars = {}

  meter.GetCaps = function(view, values)
    local val = values or {}

    val.best = 0
    val.all = 0
    val.persecond_best = 0
    val.persecond_all = 0
    val.effective_best = 0
    val.effective_all = 0
    val.effective_persecond_best = 0
    val.effective_persecond_all = 0

    for _, dat in pairs(view) do
      local v = 0

      if dat["_sum"] and dat["_ctime"] then
        val.all = val.all + dat["_sum"]
        if dat["_sum"] > val.best then
          val.best = dat["_sum"]
        end

        val.persecond_all = val.persecond_all + dat["_sum"] / dat["_ctime"]
        if dat["_sum"] / dat["_ctime"] > val.persecond_best then
          val.persecond_best = dat["_sum"] / dat["_ctime"]
        end
      end

      if dat["_esum"] and dat["_ctime"] then
        val.effective_all = val.effective_all + dat["_esum"]
        if dat["_esum"] > val.effective_all then
          val.persecond_best = dat["_esum"]
        end

        val.effective_persecond_all = val.effective_persecond_all + dat["_esum"] / dat["_ctime"]
        if dat["_esum"] / dat["_ctime"] > val.effective_persecond_best then
          val.effective_persecond_best = dat["_esum"] / dat["_ctime"]
        end
      end
    end
    return val
  end

  meter.GetData = function(unitdata, values)
    local val = values or {}

    -- read normal values
    val.value = unitdata["_sum"]
    val.value_persecond = round(val.value / unitdata["_ctime"], 1)
    val.percent = val.value == 0 and 0 or round(val.value / val.all * 100, 1)
    val.percent_persecond = val.value_persecond == 0 and 0 or
        round(val.value_persecond / val.persecond_all * 100, 1)

    -- read effective values
    if unitdata["_esum"] then
      val.effective_value = unitdata["_esum"]
      val.effective_value_persecond = round(val.effective_value / unitdata["_ctime"], 1)
      val.effective_percent = val.effective_value == 0 and 0 or
          round(val.effective_value / val.effective_all * 100, 1)
      val.effective_percent_persecond = val.effective_value_persecond == 0 and 0 or
          round(val.effective_value_persecond / val.effective_persecond_all * 100, 1)
      val.uneffective_value = val.value - val.effective_value
      val.uneffective_value_persecond = val.value_persecond - val.effective_value_persecond
    else
      val.effective_value = 0
      val.effective_value_persecond = 0
      val.effective_percent = 0
      val.effective_percent_persecond = 0
      val.uneffective_value = 0
      val.uneffective_value_persecond = 0
    end

    -- check pet and detect owner/unit names
    local pet  = not classes[data["classes"][val.name]] and data["classes"][val.name] ~= "__other__"
    local unit = pet and data["classes"][val.name] or val.name

    -- merge pet/owner strings if option is set
    if config.merge_pets == 0 then
      val.name = pet and unit .. " - " .. val.name or unit
    else
      val.name = unit
    end

    -- write color into view
    -- default to faded name colors
    local r, g, b = str2rgb(val.name)
    val.color = val.color or {}
    val.color.r = r / 4 + .4
    val.color.g = g / 4 + .4
    val.color.b = b / 4 + .4

    -- replace color by class colors if possible
    if classes[data["classes"][unit]] then
      -- set color to player class colors
      val.color.r = RAID_CLASS_COLORS[data["classes"][unit]].r
      val.color.g = RAID_CLASS_COLORS[data["classes"][unit]].g
      val.color.b = RAID_CLASS_COLORS[data["classes"][unit]].b

      if config.pastel == 1 then
        val.color.r = (val.color.r + .5) * .5
        val.color.g = (val.color.g + .5) * .5
        val.color.b = (val.color.b + .5) * .5
      end
    end

    return val
  end

  local values = {}
  local buttons = {
    meter.btnDamage,
    meter.btnDPS,
    meter.btnHeal,
    meter.btnHPS,
    meter.btnOverall,
    meter.btnCurrent
  }

  meter.Refresh = function(force, report)
    if force then
      if database.visible == 1 then
        meter:Show()
      else
        meter:Hide()
      end

      if id == 1 then
        if ShaguDPS.config.window_two.visible == 1 then
          meter.btnOpenAlt.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\minus")
        else
          meter.btnOpenAlt.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\plus")
        end
      end

      for _, button in pairs(buttons) do
        button.caption:SetTextColor(1, 1, 1, 1)
      end

      if database.backdrop == 1 then
        meter:SetBackdrop(backdrop_window)
        meter:SetBackdropColor(0.5, 0.5, 0.5, 0.5)

        meter.border:SetBackdrop(backdrop_border)
        meter.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
      else
        meter:SetBackdrop(nil)
        meter.border:SetBackdrop(nil)
      end

      if database.view == 1 then
        meter.btnDamage.caption:SetTextColor(1, 0.9, 0, 1)
        meter.btnMode.caption:SetText("Damage")
      elseif database.view == 2 then
        meter.btnDPS.caption:SetTextColor(1, 0.9, 0, 1)
        meter.btnMode.caption:SetText("DPS")
      elseif database.view == 3 then
        meter.btnHeal.caption:SetTextColor(1, 0.9, 0, 1)
        meter.btnMode.caption:SetText("Heal")
      elseif database.view == 4 then
        meter.btnHPS.caption:SetTextColor(1, 0.9, 0, 1)
        meter.btnMode.caption:SetText("HPS")
      end

      if database.segment == 0 then
        meter.btnOverall.caption:SetTextColor(1, 0.9, 0, 1)
        meter.btnSegment.caption:SetText("Overall")
      elseif database.segment == 1 then
        meter.btnCurrent.caption:SetTextColor(1, 0.9, 0, 1)
        meter.btnSegment.caption:SetText("Current")
      end

      meter:SetWidth(database.width)
      meter:SetHeight(database.height * database.bars + 22 + 4)
    end

    for _, bar in pairs(meter.bars) do
      bar.lowerBar:Hide()
      bar:Hide()
    end

    if database.view == 1 or database.view == 2 then
      segment = data.damage[(config.segment or 0)]
    elseif database.view == 3 or database.view == 4 then
      segment = data.heal[(config.segment or 0)]
    end

    local template = view_templates[database.view]
    local sort = sort_algorithms[template.sort]

    if report then
      local name = view_templates[database.view].name
      local seg = database.segment == 1 and "Current" or "Overall"
      announce("ShaguDPS - " .. seg .. " " .. name .. ":")
    end

    values = meter.GetCaps(segment, values)

    local i = 1
    for name, unitdata in spairs(segment, sort) do
      values.name = name
      values = meter.GetData(unitdata, values)

      local bar = i - scroll
      if bar >= 1 and bar <= database.bars then
        meter.bars[bar] = not force and meter.bars[bar] or CreateBar(meter, bar)

        -- attach unit and titles to bar
        meter.bars[bar].title = values.name
        meter.bars[bar].unit = name

        meter.bars[bar]:SetMinMaxValues(0, values[template.bar_max])
        meter.bars[bar]:SetValue(values[template.bar_val])

        -- enable lower bar if template requires it
        if template.bar_lower_max and template.bar_lower_val then
          meter.bars[bar].lowerBar:SetMinMaxValues(0, values[template.bar_lower_max])
          meter.bars[bar].lowerBar:SetValue(values[template.bar_lower_val])
          meter.bars[bar].lowerBar:Show()
        else
          meter.bars[bar].lowerBar:Hide()
        end

        meter.bars[bar]:SetStatusBarColor(values.color.r, values.color.g, values.color.b)
        meter.bars[bar].textLeft:SetText(i .. ". " .. values.name)

        local a = template.bar_string_params
        local line = string.format(template.bar_string,
          values[a[1]], values[a[2]], values[a[3]], values[a[4]], values[a[5]])

        meter.bars[bar].textRight:SetText(line)
        meter.bars[bar]:Show()

        if report and i <= 10 then
          local chat = string.format(template.chat_string,
            values[a[1]], values[a[2]], values[a[3]], values[a[4]], values[a[5]])

          announce(i .. ". " .. values.name .. " " .. chat)
        end
      end
      i = i + 1
    end
  end

  table.insert(parser.callbacks.refresh, function()
    meter.needs_refresh = true
  end)

  return meter
end

ShaguDPS.Windows = ShaguDPS.Windows or {}
ShaguDPS.Windows[1] = ShaguDPS:CreateMeterWindow(ShaguDPS.config.window_one, 1)
ShaguDPS.Windows[1]:SetPoint("RIGHT", UIParent, "RIGHT", -100, 82)
ShaguDPS.Windows[1].Refresh()

ShaguDPS.Windows[2] = ShaguDPS:CreateMeterWindow(ShaguDPS.config.window_two, 2)
ShaguDPS.Windows[2]:SetPoint("RIGHT", UIParent, "RIGHT", -100, -82)
ShaguDPS.Windows[2].Refresh()

function ShaguDPS:RefreshAll(force, report)
  if config.window_two.visible == 1 then
    for _, w in pairs(ShaguDPS.Windows) do
      if force then
        w.Refresh(true)
      elseif report then
        w.Refresh(nil, true)
      else
        w.Refresh()
      end
    end
  else
    if force then
      ShaguDPS.Windows[1].Refresh(true)
    elseif report then
      ShaguDPS.Windows[1].Refresh(nil, true)
    else
      ShaguDPS.Windows[1].Refresh()
    end
  end
end
