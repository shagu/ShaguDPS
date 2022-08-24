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
  WARRIOR = true, MAGE = true, ROGUE = true, DRUID = true, HUNTER = true,
  SHAMAN = true, PRIEST = true, WARLOCK = true, PALADIN = true,
}

-- default button backdrop
local backdrop =  {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
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
    chat_string = "%s (%s, %.1f%%)",
    bar_string = "%s (%s, %.1f%%)",
    bar_string_params = { "value", "value_persecond", "percent" },
  },
  [2] = { -- dps
    name = "DPS",
    sort = "per_second",
    bar_max = "persecond_best",
    bar_val = "value_persecond",
    bar_lower_max = nil,
    bar_lower_val = nil,
    chat_string = "%s (%s, %.1f%%)",
    bar_string = "%s (%s, %.1f%%)",
    bar_string_params = { "value_persecond", "value", "percent_persecond" },
  },
  [3] = { -- heal
    name = "Heal",
    sort = "normal",
    bar_max = "best",
    bar_val = "effective_value",
    bar_lower_max = "best",
    bar_lower_val = "value",
    chat_string = "[+%s] %s (%s, %.1f%%)",
    bar_string = "|cffcc8888+%s|r %s (%s, %.1f%%)",
    bar_string_params = { "uneffective_value", "effective_value", "effective_value_persecond", "effective_percent" },
  },
  [4] = { -- hps
    name = "HPS",
    sort = "per_second",
    bar_max = "persecond_best",
    bar_val = "effective_value_persecond",
    bar_lower_max = "persecond_best",
    bar_lower_val = "value_persecond",
    chat_string = "[+%s] %s (%s, %.1f%%)",
    bar_string = "|cffcc8888+%s|r %s (%s, %.1f%%)",
    bar_string_params = { "uneffective_value_persecond", "effective_value_persecond", "effective_value", "effective_percent" },
  },
}

-- panel button templates
local menubuttons = {
  -- segments
  ["Current"]  = { 0, 1, -25.5, "Current Segment", "|cffffffffShow current fight",      "segment" },
  ["Overall"]  = { 1, 0, -25.5, "Overall Segment", "|cffffffffShow all fights",         "segment" },

  -- modes
  ["Damage"]   = { 0, 1, 25.5,  "Damage View",     "|cffffffffShow Damage Done",        "view" },
  ["DPS"]      = { 1, 2, 25.5,  "DPS View",        "|cffffffffShow Damage Per Second",  "view" },
  ["Heal"]     = { 2, 3, 25.5,  "Heal View",       "|cffffffffShow Healing Done",       "view" },
  ["HPS"]      = { 3, 4, 25.5,  "HPS View",        "|cffffffffShow Heal Per Second",    "view" },
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
  normal = function(t,a,b)
    if t[a]["_esum"] and t[b]["_esum"] and t[a]["_esum"] ~= t[b]["_esum"] then
      return t[b]["_esum"] < t[a]["_esum"]
    else
      return t[b]["_sum"] < t[a]["_sum"]
    end
  end,
  per_second = function(t,a,b)
    if t[a]["_esum"] and t[b]["_esum"] and t[a]["_esum"] ~= t[b]["_esum"] then
      return t[b]["_esum"] / t[b]["_ctime"] < t[a]["_esum"] / t[a]["_ctime"]
    else
      return t[b]["_sum"] / t[b]["_ctime"] < t[a]["_sum"] / t[a]["_ctime"]
    end
  end,
  single_spell = function(t,a,b)
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
    counter = mod(counter*8161, 4294967279) +
        (string.byte(text,i)*16776193) +
        ((string.byte(text,i+1) or (l-i+256))*8372226) +
        ((string.byte(text,i+2) or (l-i+256))*3932164)
  end
  local hash = mod(mod(counter, 4294967291),16777216)
  local r = (hash - (mod(hash,65536))) / 65536
  local g = ((hash - r*65536) - ( mod((hash - r*65536),256)) ) / 256
  local b = hash - r*65536 - g*256
  rgbcache[text] = { r / 255, g / 255, b / 255 }
  return unpack(rgbcache[text])
end

local function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[table.getn(keys)+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a,b) return order(t, a, b) end)
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

local function barTooltipShow()
  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")

  local value = segment[this.unit]["_sum"]
  local persec = round(segment[this.unit]["_sum"] / segment[this.unit]["_ctime"], 1)

  GameTooltip:AddLine(this.unit .. ":")

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
      local percent = damage == 0 and 0 or round(damage / segment[this.unit]["_sum"] * 100,1)
      if segment[this.unit]["_effective"] and segment[this.unit]["_effective"][attack] then
        -- heal / effective heal
        local effective = segment[this.unit]["_effective"][attack]
        local epercent = effective == 0 and 0 or round(effective / segment[this.unit]["_esum"] * 100,1)

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
  for k,v in pairs(segment) do
    count = count + 1
  end

  scroll = math.min(scroll, count + 1 - config.bars)
  scroll = math.max(scroll, 0)

  window.Refresh()
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
  window.Refresh()
end

local function CreateBar(parent, i, background)
  parent.bars[i] = parent.bars[i] or CreateFrame("StatusBar", "ShaguDPSBar" .. i, parent)
  parent.bars[i]:SetStatusBarTexture(textures[config.texture] or textures[1])
  parent.bars[i]:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -config.height * (i-1) - 22)
  parent.bars[i]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -config.height * (i-1) - 22)
  parent.bars[i]:SetHeight(config.height)
  parent.bars[i]:SetFrameLevel(4)

  parent.bars[i].lowerBar = parent.bars[i].lowerBar or CreateFrame("StatusBar", "ShaguDPSLowerBar" .. i, parent)
  parent.bars[i].lowerBar:SetStatusBarTexture(textures[config.texture] or textures[1])
  parent.bars[i].lowerBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -config.height * (i-1) - 22)
  parent.bars[i].lowerBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -config.height * (i-1) - 22)
  parent.bars[i].lowerBar:SetStatusBarColor(1, 1, 1, .4)
  parent.bars[i].lowerBar:SetHeight(config.height)
  parent.bars[i].lowerBar:SetFrameLevel(2)

  parent.bars[i].textLeft = parent.bars[i].textLeft or parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
  parent.bars[i].textLeft:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  parent.bars[i].textLeft:SetJustifyH("LEFT")
  parent.bars[i].textLeft:SetFontObject(GameFontWhite)
  parent.bars[i].textLeft:SetParent(parent.bars[i])
  parent.bars[i].textLeft:ClearAllPoints()
  parent.bars[i].textLeft:SetPoint("TOPLEFT", parent.bars[i], "TOPLEFT", 5, 1)
  parent.bars[i].textLeft:SetPoint("BOTTOMRIGHT", parent.bars[i], "BOTTOMRIGHT", -5, 0)

  parent.bars[i].textRight = parent.bars[i].textRight or parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
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

  this:SetBackdropBorderColor(1,.9,0,1)
end

local function btnLeave()
  if this.tooltip then
    GameTooltip:Hide()
  end

  this:SetBackdropBorderColor(.4,.4,.4,1)
end

window:ClearAllPoints()
window:SetPoint("RIGHT", UIParent, "RIGHT", -100, -100)

window:EnableMouse(true)
window:EnableMouseWheel(1)
window:RegisterForDrag("LeftButton")
window:SetMovable(true)
window:SetUserPlaced(true)
window:SetScript("OnDragStart", function() window:StartMoving() end)
window:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
window:SetScript("OnMouseWheel", barScrollWheel)
window:SetClampedToScreen(true)
window:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
window:SetBackdropColor(.5,.5,.5,.5)

window.title = window:CreateTexture(nil, "NORMAL")
window.title:SetTexture(0,0,0,.6)
window.title:SetHeight(20)
window.title:SetPoint("TOPLEFT", 2, -2)
window.title:SetPoint("TOPRIGHT", -2, -2)

window.btnSegment = CreateFrame("Button", "ShaguDPSDamage", window)
window.btnSegment:SetPoint("CENTER", window.title, "CENTER", -25.5, 0)
window.btnSegment:SetFrameStrata("MEDIUM")
window.btnSegment:SetHeight(16)
window.btnSegment:SetWidth(50)
window.btnSegment:SetBackdrop(backdrop)
window.btnSegment:SetBackdropColor(.2,.2,.2,1)
window.btnSegment:SetBackdropBorderColor(.4,.4,.4,1)

window.btnSegment.caption = window.btnSegment:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
window.btnSegment.caption:SetFont(STANDARD_TEXT_FONT, 9)
window.btnSegment.caption:SetText("Overall")
window.btnSegment.caption:SetAllPoints()
window.btnSegment.tooltip = { "Select Segment", "|cffffffffOverall, Current" }
window.btnSegment:SetScript("OnEnter", btnEnter)
window.btnSegment:SetScript("OnLeave", btnLeave)
window.btnSegment:SetScript("OnClick", function()
  if window.btnCurrent:IsShown() then
    window.btnDamage:Hide()
    window.btnDPS:Hide()
    window.btnHeal:Hide()
    window.btnHPS:Hide()
    window.btnOverall:Hide()
    window.btnCurrent:Hide()
  else
    window.btnDamage:Hide()
    window.btnDPS:Hide()
    window.btnHeal:Hide()
    window.btnHPS:Hide()
    window.btnOverall:Show()
    window.btnCurrent:Show()
  end
end)

window.btnMode = CreateFrame("Button", "ShaguDPSDamage", window)
window.btnMode:SetPoint("CENTER", window.title, "CENTER", 25.5, 0)
window.btnMode:SetFrameStrata("MEDIUM")
window.btnMode:SetHeight(16)
window.btnMode:SetWidth(50)
window.btnMode:SetBackdrop(backdrop)
window.btnMode:SetBackdropColor(.2,.2,.2,1)
window.btnMode:SetBackdropBorderColor(.4,.4,.4,1)

window.btnMode.caption = window.btnMode:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
window.btnMode.caption:SetFont(STANDARD_TEXT_FONT, 9)
window.btnMode.caption:SetText("Mode: Damage")
window.btnMode.caption:SetAllPoints()
window.btnMode.tooltip = { "Select Mode", "|cffffffffDamage, DPS, Heal, HPS" }
window.btnMode:SetScript("OnEnter", btnEnter)
window.btnMode:SetScript("OnLeave", btnLeave)
window.btnMode:SetScript("OnClick", function()
  if window.btnDamage:IsShown() then
    window.btnDamage:Hide()
    window.btnDPS:Hide()
    window.btnHeal:Hide()
    window.btnHPS:Hide()
    window.btnOverall:Hide()
    window.btnCurrent:Hide()
  else
    window.btnDamage:Show()
    window.btnDPS:Show()
    window.btnHeal:Show()
    window.btnHPS:Show()
    window.btnOverall:Hide()
    window.btnCurrent:Hide()
  end
end)

for name, template in pairs(menubuttons) do
  window["btn"..name] = CreateFrame("Button", "ShaguDPS" .. name, window)

  local button = window["btn"..name]
  local template = template

  button:SetPoint("CENTER", window.title, "CENTER", template[3], 18+template[1]*16)
  button:SetFrameStrata("MEDIUM")
  button:SetHeight(16)
  button:SetWidth(50)
  button:SetBackdrop(backdrop)
  button:SetBackdropColor(.2,.2,.2,1)
  button:SetBackdropBorderColor(.4,.4,.4,1)
  button:Hide()

  button.caption = button:CreateFontString("ShaguDPS"..name.."Title", "OVERLAY", "GameFontWhite")
  button.caption:SetFont(STANDARD_TEXT_FONT, 9)
  button.caption:SetText(name)
  button.caption:SetAllPoints()
  button.tooltip = { template[4], template[5] }
  button:SetScript("OnEnter", btnEnter)
  button:SetScript("OnLeave", btnLeave)
  button:SetScript("OnClick", function()
    config[template[6]] = template[2]
    window.Refresh(true)

    for button in pairs(menubuttons) do
      window["btn"..button]:Hide()
    end
  end)
end

window.btnReset = CreateFrame("Button", "ShaguDPSReset", window)
window.btnReset:SetPoint("RIGHT", window.title, "RIGHT", -4, 0)
window.btnReset:SetFrameStrata("MEDIUM")
window.btnReset:SetHeight(16)
window.btnReset:SetWidth(16)
window.btnReset:SetBackdrop(backdrop)
window.btnReset:SetBackdropColor(.2,.2,.2,1)
window.btnReset:SetBackdropBorderColor(.4,.4,.4,1)
window.btnReset.tooltip = {
  "Reset Data",
  { "|cffffffffClick", "|cffaaaaaaAsk to reset all data."},
  { "|cffffffffShift-Click", "|cffaaaaaaReset all data."},
}

window.btnReset.tex = window.btnReset:CreateTexture()
window.btnReset.tex:SetWidth(10)
window.btnReset.tex:SetHeight(10)
window.btnReset.tex:SetPoint("CENTER", 0, 0)
window.btnReset.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\reset")
window.btnReset:SetScript("OnEnter", btnEnter)
window.btnReset:SetScript("OnLeave", btnLeave)
window.btnReset:SetScript("OnClick", function()
  if IsShiftKeyDown() then
    ResetData()
  else
    local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
    dialog.text = "Do you wish to reset the data?"
    dialog.OnAccept = ResetData
    StaticPopup_Show("SHAGUMETER_QUESTION")
  end
end)

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

window.btnAnnounce = CreateFrame("Button", "ShaguDPSReset", window)
window.btnAnnounce:SetPoint("LEFT", window.title, "LEFT", 4, 0)
window.btnAnnounce:SetFrameStrata("MEDIUM")
window.btnAnnounce:SetHeight(16)
window.btnAnnounce:SetWidth(16)
window.btnAnnounce:SetBackdrop(backdrop)
window.btnAnnounce:SetBackdropColor(.2,.2,.2,1)
window.btnAnnounce:SetBackdropBorderColor(.4,.4,.4,1)
window.btnAnnounce.tooltip = {
  "Send to Chat",
  { "|cffffffffClick", "|cffaaaaaaAsk to anounce all data."},
  { "|cffffffffShift-Click", "|cffaaaaaaAnnounce all data."},
}

window.btnAnnounce.tex = window.btnAnnounce:CreateTexture()
window.btnAnnounce.tex:SetWidth(10)
window.btnAnnounce.tex:SetHeight(10)
window.btnAnnounce.tex:SetPoint("CENTER", 0, 0)
window.btnAnnounce.tex:SetTexture("Interface\\AddOns\\ShaguDPS" .. (tbc and "-tbc" or "") .. "\\img\\announce")
window.btnAnnounce:SetScript("OnEnter", btnEnter)
window.btnAnnounce:SetScript("OnLeave", btnLeave)
window.btnAnnounce:SetScript("OnClick", function()
  if IsShiftKeyDown() then
    -- reload / anounce
    window.Refresh(nil, true)
  else
    local ctype = tbc and ChatFrameEditBox:GetAttribute("chatType") or ChatFrameEditBox.chatType
    local color = chatcolors[ctype]
    if not color then color = "|cff00FAF6" end

    local name = view_templates[config.view].name
    local text = "Post |cffffdd00" .. name .. "|r data into /" .. color..string.lower(ctype) .. "|r?"

    local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
    dialog.text = text

    dialog.OnAccept = function() window.Refresh(nil, true) end
    StaticPopup_Show("SHAGUMETER_QUESTION")
  end
end)

window.border = CreateFrame("Frame", "ShaguDPSBorder", window)
window.border:ClearAllPoints()
window.border:SetPoint("TOPLEFT", window, "TOPLEFT", -1,1)
window.border:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 1,-1)
window.border:SetBackdrop({
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
window.border:SetBackdropBorderColor(.7,.7,.7,1)
window.border:SetFrameLevel(100)

window.bars = {}

window.GetCaps = function(view, values)
  local values = values or {}

  -- reset/empty values
  values.best = 0
  values.all = 0
  values.persecond_best = 0
  values.persecond_all = 0
  values.effective_best = 0
  values.effective_all = 0
  values.effective_persecond_best = 0
  values.effective_persecond_all = 0

  for name, data in pairs(view) do
    local val = 0

    -- calculate normal values
    if data["_sum"] and data["_ctime"] then
      values.all = values.all + data["_sum"]
      if data["_sum"] > values.best then
        values.best = data["_sum"]
      end

      values.persecond_all = values.persecond_all + data["_sum"] / data["_ctime"]
      if data["_sum"] / data["_ctime"] > values.persecond_best then
        values.persecond_best = data["_sum"] / data["_ctime"]
      end
    end

    -- calculate effective values
    if data["_esum"] and data["_ctime"] then
      values.effective_all = values.effective_all + data["_esum"]
      if data["_esum"] > values.effective_all then
        values.persecond_best = data["_esum"]
      end

      values.effective_persecond_all = values.effective_persecond_all + data["_esum"] / data["_ctime"]
      if data["_esum"] / data["_ctime"] > values.effective_persecond_best then
        values.effective_persecond_best = data["_esum"] / data["_ctime"]
      end
    end
  end

  return values
end

window.GetData = function(unitdata, values)
  local values = values or {}

  -- read normal values
  values.value = unitdata["_sum"]
  values.value_persecond = round(values.value / unitdata["_ctime"], 1)
  values.percent = values.value == 0 and 0 or round(values.value / values.all * 100,1)
  values.percent_persecond = values.value_persecond == 0 and 0 or round(values.value_persecond / values.persecond_all * 100, 1)

  -- read effective values
  if unitdata["_esum"] then
    values.effective_value = unitdata["_esum"]
    values.effective_value_persecond = round(values.effective_value / unitdata["_ctime"], 1)
    values.effective_percent = values.effective_value == 0 and 0 or round(values.effective_value / values.effective_all * 100, 1)
    values.effective_percent_persecond = values.effective_value_persecond == 0 and 0 or round(values.effective_value_persecond / values.effective_persecond_all * 100,1)
    values.uneffective_value = values.value - values.effective_value
    values.uneffective_value_persecond = values.value_persecond - values.effective_value_persecond
  else
    values.effective_value = 0
    values.effective_value_persecond = 0
    values.effective_percent = 0
    values.effective_percent_persecond = 0
    values.uneffective_value = 0
    values.uneffective_value_persecond = 0
  end

  -- check pet and detect owner/unit names
  local pet  = not classes[data["classes"][values.name]] and data["classes"][values.name] ~= "__other__"
  local unit = pet and data["classes"][values.name] or values.name

  -- merge pet/owner strings if option is set
  if config.merge_pets == 0 then
    values.name = pet and unit .. " - " .. values.name or unit
  else
    values.name = unit
  end

  -- write color into view
  -- default to faded name colors
  local r, g, b = str2rgb(values.name)
  values.color = values.color or {}
  values.color.r = r / 4 + .4
  values.color.g = g / 4 + .4
  values.color.b = b / 4 + .4

  -- replace color by class colors if possible
  if classes[data["classes"][unit]] then
    -- set color to player class colors
    values.color.r = RAID_CLASS_COLORS[data["classes"][unit]].r
    values.color.g = RAID_CLASS_COLORS[data["classes"][unit]].g
    values.color.b = RAID_CLASS_COLORS[data["classes"][unit]].b
  end

  return values
end

local values = {}
window.Refresh = function(force, report)
  -- config changes
  if force then
    if config.visible == 1 then
      window:Show()
    else
      window:Hide()
    end

    for _, button in pairs({window.btnDamage, window.btnDPS, window.btnHeal, window.btnHPS}) do
      button.caption:SetTextColor(.5,.5,.5,1)
    end

    -- update panel button appearance
    if config.view == 1 then
      window.btnDamage.caption:SetTextColor(1,.9,0,1)
      window.btnMode.caption:SetText("Damage")
    elseif config.view == 2 then
      window.btnDPS.caption:SetTextColor(1,.9,0,1)
      window.btnMode.caption:SetText("DPS")
    elseif config.view == 3 then
      window.btnHeal.caption:SetTextColor(1,.9,0,1)
      window.btnMode.caption:SetText("Heal")
    elseif config.view == 4 then
      window.btnHPS.caption:SetTextColor(1,.9,0,1)
      window.btnMode.caption:SetText("HPS")
    end

    if config.segment == 0 then
      window.btnOverall.caption:SetTextColor(1,.9,0,1)
      window.btnCurrent.caption:SetTextColor(.5,.5,.5,1)
      window.btnSegment.caption:SetText("Overall")
    elseif config.segment == 1 then
      window.btnOverall.caption:SetTextColor(.5,.5,.5,1)
      window.btnCurrent.caption:SetTextColor(1,.9,0,1)
      window.btnSegment.caption:SetText("Current")
    end

    window:SetWidth(config.width)
    window:SetHeight(config.height * config.bars + 22 + 4)
  end

  -- clear previous results
  for id, bar in pairs(window.bars) do
    bar.lowerBar:Hide()
    bar:Hide()
  end

  -- set view to damage or heal
  if config.view == 1 or config.view == 2 then
    segment = data.damage[(config.segment or 0)]
  elseif config.view == 3 or config.view == 4 then
    segment = data.heal[(config.segment or 0)]
  end

  -- read view settings
  local view_per_second = (config.view == 2 or config.view == 4) and true or nil
  local view_effective  = (config.view == 3 or config.view == 4) and true or nil

  local template = view_templates[config.view]
  local sort = sort_algorithms[template.sort]

  -- report to chat if flag is set
  if report then
    local name = view_templates[config.view].name
    local seg = config.segment == 1 and "Current" or "Overall"
    announce("ShaguDPS - " .. seg .. " " .. name .. ":")
  end

  -- load caps of the current view
  values = window.GetCaps(segment, values)

  local i = 1
  for name, unitdata in spairs(segment, sort) do
    -- attach name to values
    values.name = name

    -- load data values of the current unit
    values = window.GetData(unitdata, values)

    local bar = i - scroll
    if bar >= 1 and bar <= config.bars then
      window.bars[bar] = not force and window.bars[bar] or CreateBar(window, bar)
      window.bars[bar].unit = values.name

      window.bars[bar]:SetMinMaxValues(0, values[template.bar_max])
      window.bars[bar]:SetValue(values[template.bar_val])

      -- enable lower bar if template requires it
      if template.bar_lower_max and template.bar_lower_val then
        window.bars[bar].lowerBar:SetMinMaxValues(0, values[template.bar_lower_max])
        window.bars[bar].lowerBar:SetValue(values[template.bar_lower_val])
        window.bars[bar].lowerBar:Show()
      else
        window.bars[bar].lowerBar:Hide()
      end

      window.bars[bar]:SetStatusBarColor(values.color.r, values.color.g, values.color.b)
      window.bars[bar].textLeft:SetText(i .. ". " .. values.name)

      local a = template.bar_string_params
      local line = string.format(template.bar_string,
        values[a[1]], values[a[2]], values[a[3]], values[a[4]], values[a[5]])

      window.bars[bar].textRight:SetText(line)
      window.bars[bar]:Show()

      -- report to chat if flag is set
      if report and i <= 10 then
        local chat = string.format(template.chat_string,
          values[a[1]], values[a[2]], values[a[3]], values[a[4]], values[a[5]])

        announce(i .. ". " .. values.name .. " " .. chat)
      end
    end

    i = i + 1
  end
end

table.insert(parser.callbacks.refresh, window.Refresh)
