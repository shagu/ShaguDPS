-- load public variables into local
local window = ShaguMeter.window
local parser = ShaguMeter.parser

local textures = ShaguMeter.textures
local spairs = ShaguMeter.spairs

local playerClasses = ShaguMeter.playerClasses
local view_dmg_all = ShaguMeter.view_dmg_all
local dmg_table = ShaguMeter.dmg_table
local config = ShaguMeter.config

local scroll = 0
local view_dmg_all_max = 0

local backdrop =  {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
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
  GameTooltip:AddDoubleLine("|cffffee00Damage Done", "|cffffffff" .. dmg_table[this.unit]["_sum"])
  for attack, damage in spairs(dmg_table[this.unit], function(t,a,b) return t[b] < t[a] end) do
    if attack ~= "_sum" then
      GameTooltip:AddDoubleLine("|cffffffff" .. attack, "|cffcccccc" .. damage .. " - |cffffffff" .. round(damage / dmg_table[this.unit]["_sum"] * 100,1) .. "%")
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
  for k,v in pairs(view_dmg_all) do
    count = count + 1
  end

  scroll = math.min(scroll, count + 1 - config.bars)
  scroll = math.max(scroll, 0)

  window.Refresh()
end

local function CreateBar(parent, i)
  parent.bars[i] = parent.bars[i] or CreateFrame("StatusBar", "ShaguMeterBar" .. i, parent)
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

window.title = window:CreateTexture(nil, "NORMAL")
window.title:SetTexture(0,0,0,.6)
window.title:SetHeight(20)

window.titleText = window:CreateFontString("ShaguMeterTitle", "OVERLAY", "GameFontWhite")
window.titleText:SetAllPoints(window.title)
window.titleText:SetText("ShaguMeter")

window.btnReset = CreateFrame("Button", "ShaguMeterReset", window)
window.btnReset:SetPoint("RIGHT", window.title, "RIGHT", -4, 0)
window.btnReset:SetFrameStrata("MEDIUM")

window.btnReset.tex = window.btnReset:CreateTexture()
window.btnReset.tex:SetWidth(10)
window.btnReset.tex:SetHeight(10)
window.btnReset.tex:SetPoint("CENTER", 0, 0)
window.btnReset.tex:SetTexture("Interface\\AddOns\\ShaguMeter\\img\\reset")
window.btnReset:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(1,.9,0,1)
end)

window.btnReset:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(.4,.4,.4,1)
end)

window.btnReset:SetScript("OnClick", function()
  local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
  dialog.text = "Do you wish to reset the data?"
  dialog.OnAccept = function()
    for k, v in pairs(dmg_table) do
      dmg_table[k] = nil
    end

    for k, v in pairs(view_dmg_all) do
      view_dmg_all[k] = nil
    end

    view_dmg_all_max = 0
    scroll = 0
    window:Refresh()
  end
  StaticPopup_Show("SHAGUMETER_QUESTION")
end)

window.btnAnnounce = CreateFrame("Button", "ShaguMeterReset", window)
window.btnAnnounce:SetPoint("LEFT", window.title, "LEFT", 4, 0)
window.btnAnnounce:SetFrameStrata("MEDIUM")

window.btnAnnounce.tex = window.btnAnnounce:CreateTexture()
window.btnAnnounce.tex:SetWidth(10)
window.btnAnnounce.tex:SetHeight(10)
window.btnAnnounce.tex:SetPoint("CENTER", 0, 0)
window.btnAnnounce.tex:SetTexture("Interface\\AddOns\\ShaguMeter\\img\\announce")
window.btnAnnounce:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(1,.9,0,1)
end)

window.btnAnnounce:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(.4,.4,.4,1)
end)

local function announce(text)
  local type      = DEFAULT_CHAT_FRAME.editBox.chatType
  local language  = DEFAULT_CHAT_FRAME.editBox.language
  local channel   = DEFAULT_CHAT_FRAME.editBox.channelTarget
  local target    = DEFAULT_CHAT_FRAME.editBox.tellTarget
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

window.btnAnnounce:SetScript("OnClick", function()
  local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]

  local ctype = DEFAULT_CHAT_FRAME.editBox.chatType
  local color = chatcolors[ctype]
  if not color then color = "|cff00FAF6" end

  dialog.text = "Post damage data into chat?\n\n-> "..color..string.lower(ctype).."|r <-\n\n"
  dialog.OnAccept = function()
    local sum_dmg, count = 0, 0
    for _, damage in pairs(view_dmg_all) do
      count = count + 1
      sum_dmg = sum_dmg + damage

      if damage > view_dmg_all_max then
        view_dmg_all_max = damage
      end
    end

    if count <= 0 then return end

    announce("ShaguMeter - Damage Done:")
    local i = 1
    for name, damage in spairs(view_dmg_all, function(t,a,b) return t[b] < t[a] end) do
      if i <= 5 then
        announce(i .. ". " .. name .. " " .. damage .. " (" .. round(damage / sum_dmg * 100,1) .. "%)")
      end
      i = i + 1
    end
  end
  StaticPopup_Show("SHAGUMETER_QUESTION")
end)

window.border = CreateFrame("Frame", "ShaguMeterBorder", window)
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

window.Refresh = function(force)
  -- config changes
  if force then
    if config.visible == 1 then
      window:Show()
    else
      window:Hide()
    end

    window:SetWidth(config.width)
    window:SetHeight(config.height * config.bars + 22 + 4)

    -- pfUI skin
    if config.pfui == 1 and pfUI and pfUI.uf and pfUI.api.CreateBackdrop then
      window.btnAnnounce:SetHeight(14)
      window.btnAnnounce:SetWidth(14)

      window.btnReset:SetHeight(14)
      window.btnReset:SetWidth(14)

      window.title:SetPoint("TOPLEFT", 1, -1)
      window.title:SetPoint("TOPRIGHT", -1, -1)

      pfUI.api.CreateBackdrop(window, nil, true, .75)
      pfUI.api.CreateBackdrop(window.btnAnnounce, nil, true, .75)
      pfUI.api.CreateBackdrop(window.btnReset, nil, true, .75)

      window.btnAnnounce:SetBackdropBorderColor(.4,.4,.4,1)
      window.btnReset:SetBackdropBorderColor(.4,.4,.4,1)

      window.border:Hide()
    else
      window.btnAnnounce:SetHeight(16)
      window.btnAnnounce:SetWidth(16)

      window.btnReset:SetHeight(16)
      window.btnReset:SetWidth(16)

      window.title:SetPoint("TOPLEFT", 2, -2)
      window.title:SetPoint("TOPRIGHT", -2, -2)

      window:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
      })
      window:SetBackdropColor(.5,.5,.5,.5)

      window.btnAnnounce:SetBackdrop(backdrop)
      window.btnAnnounce:SetBackdropColor(.2,.2,.2,1)
      window.btnAnnounce:SetBackdropBorderColor(.4,.4,.4,1)

      window.btnReset:SetBackdrop(backdrop)
      window.btnReset:SetBackdropColor(.2,.2,.2,1)
      window.btnReset:SetBackdropBorderColor(.4,.4,.4,1)

      window.border:Show()
    end
  end

  local count = 0
  local sum_dmg = 0
  for _, damage in pairs(view_dmg_all) do
    count = count + 1
    sum_dmg = sum_dmg + damage

    if damage > view_dmg_all_max then
      view_dmg_all_max = damage
    end
  end

  -- clear previous results
  for id, bar in pairs(window.bars) do
    bar:Hide()
  end

  local i = 1
  for name, damage in spairs(view_dmg_all, function(t,a,b) return t[b] < t[a] end) do
    local bar = i - scroll

    if bar >= 1 and bar <= config.bars then
      window.bars[bar] = not force and window.bars[bar] or CreateBar(window, bar)
      window.bars[bar]:SetMinMaxValues(0, view_dmg_all_max)
      window.bars[bar]:SetValue(damage)
      window.bars[bar]:Show()
      window.bars[bar].unit = name

      local color = { r= .4, g = .4, b = .4 }
      if playerClasses[name] ~= "other" then
        color = { r= .6, g = 1, b = .6 }
      end
      if RAID_CLASS_COLORS[playerClasses[name]] then
        color = RAID_CLASS_COLORS[playerClasses[name]]
      elseif playerClasses[name] then
        -- parse pet owners
        if strsub(playerClasses[name],0,3) == "pet" then
          name = UnitName("player") .. " - " .. name
        elseif strsub(playerClasses[name],0,8) == "partypet" then
          name = UnitName("party" .. strsub(playerClasses[name],9)) .. " - " .. name
        elseif strsub(playerClasses[name],0,7) == "raidpet" then
          name = UnitName("raid" .. strsub(playerClasses[name],8)) .. " - " .. name
        end
      end

      window.bars[bar]:SetStatusBarColor(color.r, color.g, color.b)

      window.bars[bar].textLeft:SetText(i .. ". " .. name)
      window.bars[bar].textRight:SetText(damage .. " - " .. round(damage / sum_dmg * 100,1) .. "%")
    end

    i = i + 1
  end
end

table.insert(parser.callbacks.refresh, window.Refresh)
