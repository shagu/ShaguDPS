-- check for expansion
local tbc = ShaguDPS.expansion() == "tbc" and true or nil

-- all known classes
local classes = {
  WARRIOR = true, MAGE = true, ROGUE = true, DRUID = true, HUNTER = true,
  SHAMAN = true, PRIEST = true, WARLOCK = true, PALADIN = true,
}

-- load public variables into local
local window = ShaguDPS.window
local parser = ShaguDPS.parser

local data = ShaguDPS.data
local config = ShaguDPS.config

local textures = ShaguDPS.textures
local spairs = ShaguDPS.spairs
local round = ShaguDPS.round

local scroll = 0
local segment = data.damage[0]

local backdrop =  {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
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

local sort_all = function(t,a,b)
  return t[b]["_sum"] < t[a]["_sum"]
end

local sort_dps = function(t,a,b)
  return t[b]["_sum"] / t[b]["_ctime"] < t[a]["_sum"] / t[a]["_ctime"]
end

local function barTooltipShow()
  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")

  local damage = segment[this.unit]["_sum"]
  local dps = round(segment[this.unit]["_sum"] / segment[this.unit]["_ctime"], 1)

  if config.view == 1 then
    GameTooltip:AddDoubleLine("|cffffee00Damage Done", "|cffffffff" .. damage)
    GameTooltip:AddDoubleLine("|cffffee00DPS", "|cffffffff" .. dps)
  else
    GameTooltip:AddDoubleLine("|cffffee00DPS", "|cffffffff" .. dps)
    GameTooltip:AddDoubleLine("|cffffee00Damage Done", "|cffffffff" .. damage)
  end

  GameTooltip:AddLine(" ")
  for attack, damage in spairs(segment[this.unit], function(t,a,b) return t[b] < t[a] end) do
    if attack ~= "_sum" and attack ~= "_ctime" and attack ~= "_tick" then
      GameTooltip:AddDoubleLine("|cffffffff" .. attack, "|cffcccccc" .. damage .. " - |cffffffff" .. string.format("%.1f",round(damage / segment[this.unit]["_sum"] * 100,1)) .. "%")
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

  -- reset scroll and reload
  scroll = 0
  window.Refresh()
end

local function CreateBar(parent, i)
  parent.bars[i] = parent.bars[i] or CreateFrame("StatusBar", "ShaguDPSBar" .. i, parent)
  parent.bars[i]:SetStatusBarTexture(textures[config.texture] or textures[1])

  parent.bars[i]:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -config.height * (i-1) - 22)
  parent.bars[i]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -config.height * (i-1) - 22)
  parent.bars[i]:SetHeight(config.height)

  parent.bars[i].textLeft = parent.bars[i].textLeft or parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
  parent.bars[i].textLeft:SetFont(STANDARD_TEXT_FONT, 12, "THINOUTLINE")
  parent.bars[i].textLeft:SetJustifyH("LEFT")
  parent.bars[i].textLeft:SetFontObject(GameFontWhite)
  parent.bars[i].textLeft:SetParent(parent.bars[i])
  parent.bars[i].textLeft:ClearAllPoints()
  parent.bars[i].textLeft:SetPoint("TOPLEFT", parent.bars[i], "TOPLEFT", 5, 1)
  parent.bars[i].textLeft:SetPoint("BOTTOMRIGHT", parent.bars[i], "BOTTOMRIGHT", -5, 0)

  parent.bars[i].textRight = parent.bars[i].textRight or parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
  parent.bars[i].textRight:SetFont(STANDARD_TEXT_FONT, 12, "THINOUTLINE")
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
    window.btnOverall:Hide()
    window.btnCurrent:Hide()
  else
    window.btnDamage:Hide()
    window.btnDPS:Hide()
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
window.btnMode.tooltip = { "Select Mode", "|cffffffffDamage, DPS" }
window.btnMode:SetScript("OnEnter", btnEnter)
window.btnMode:SetScript("OnLeave", btnLeave)
window.btnMode:SetScript("OnClick", function()
  if window.btnDamage:IsShown() then
    window.btnDamage:Hide()
    window.btnDPS:Hide()
    window.btnOverall:Hide()
    window.btnCurrent:Hide()
  else
    window.btnDamage:Show()
    window.btnDPS:Show()
    window.btnOverall:Hide()
    window.btnCurrent:Hide()
  end
end)

local menubuttons = {
  -- segments
  ["Current"]  = { 0, 1, -25.5, "Current Segment", "|cffffffffShows the current fight", "segment" },
  ["Overall"]  = { 1, 0, -25.5, "Overall Segment", "|cffffffffShows all fights",        "segment" },

  -- modes
  ["DPS"]      = { 0, 2, 25.5,  "DPS View",        "|cffffffffShows the DPS",           "view" },
  ["Damage"]   = { 1, 1, 25.5,  "Damage View",     "|cffffffffShows the Damage",        "view" },
}

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

local function AnnounceData()
  local view = config.view
  local seg = config.segment == 1 and "Current" or "Overall"
  local name = config.view == 1 and "Damage" or "DPS"

  -- get current maximum values
  local per_second = config.view == 2 and true or nil
  local sort = per_second and sort_dps or sort_all
  local best, all = window.GetCaps(segment, per_second)

  -- load current maximum damage
  local best, all = window.GetCaps(segment)
  if all <= 0 then return end

  -- announce all entries to chat
  announce("ShaguDPS - " .. seg .. " " .. name .. ":")

  local i = 1
  for name, combat_data in spairs(segment, sort) do
    local damage = per_second and combat_data["_sum"] / combat_data["_ctime"] or combat_data["_sum"]
    damage = round(damage, 1)

    if i <= 10 then
      announce(i .. ". " .. name .. " " .. damage .. " (" .. string.format("%.1f",round(damage / all * 100,1)) .. "%)")
    end
    i = i + 1
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
    AnnounceData()
  else
    local ctype = tbc and ChatFrameEditBox:GetAttribute("chatType") or ChatFrameEditBox.chatType
    local color = chatcolors[ctype]
    if not color then color = "|cff00FAF6" end

    local name = config.view == 1 and "Damage Done" or "Overall DPS"
    local text = "Post |cffffdd00" .. name .. "|r data into /" .. color..string.lower(ctype) .. "|r?"

    local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
    dialog.text = text
    dialog.OnAccept = AnnounceData
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

window.GetCaps = function(view, per_second)
  local best, all = 0, 0

  for name, data in pairs(view) do
    local val = 0

    -- only add value if source already did damage
    if data["_sum"] and data["_ctime"] then
      val = per_second and data["_sum"] / data["_ctime"] or data["_sum"]
    end

    all = all + val

    if val > best then
      best = val
    end
  end

  return best, all
end

window.Refresh = function(force)
  segment = data.damage[(config.segment or 0)]

  -- config changes
  if force then
    if config.visible == 1 then
      window:Show()
    else
      window:Hide()
    end

    if config.view == 1 then
      window.btnDamage.caption:SetTextColor(1,.9,0,1)
      window.btnDPS.caption:SetTextColor(.5,.5,.5,1)
      window.btnMode.caption:SetText("Damage")
    elseif config.view == 2 then
      window.btnDamage.caption:SetTextColor(.5,.5,.5,1)
      window.btnDPS.caption:SetTextColor(1,.9,0,1)
      window.btnMode.caption:SetText("DPS")
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
    bar:Hide()
  end

  -- get current maximum values
  local per_second = config.view == 2 and true or nil
  local sort = per_second and sort_dps or sort_all
  local best, all = window.GetCaps(segment, per_second)

  local i = 1
  for name, combat_data in spairs(segment, sort) do
    local damage = per_second and combat_data["_sum"] / combat_data["_ctime"] or combat_data["_sum"]
    damage = round(damage, 1)

    local bar = i - scroll

    if bar >= 1 and bar <= config.bars then
      window.bars[bar] = not force and window.bars[bar] or CreateBar(window, bar)
      window.bars[bar]:SetMinMaxValues(0, best)
      window.bars[bar]:SetValue(damage)
      window.bars[bar]:Show()
      window.bars[bar].unit = name

      local r, g, b = str2rgb(name)
      local color = { r = r / 4 + .4, g = g / 4 + .4, b = b / 4 + .4 }

      if classes[data["classes"][name]] then
        -- set color to player class colors
        color = RAID_CLASS_COLORS[data["classes"][name]]
      elseif data["classes"][name] ~= "__other__" then
        -- set color to player pet colors
        -- pets have their class set to the owners name
        local owner = data["classes"][name]
        if classes[data["classes"][owner]] then
          color = RAID_CLASS_COLORS[data["classes"][owner]]

          -- overwrite pet name
          if config.merge_pets == 0 then
            name = owner .. " - " .. name
          else
            name = owner
          end
        end
      end

      window.bars[bar]:SetStatusBarColor(color.r, color.g, color.b)

      window.bars[bar].textLeft:SetText(i .. ". " .. name)
      window.bars[bar].textRight:SetText(damage .. " - " .. string.format("%.1f",round(damage / all * 100,1)) .. "%")
    end

    i = i + 1
  end
end

table.insert(parser.callbacks.refresh, window.Refresh)
