-- load public variables into local
local window = ShaguDPS.window
local parser = ShaguDPS.parser

local textures = ShaguDPS.textures
local spairs = ShaguDPS.spairs

local playerClasses = ShaguDPS.playerClasses
local view_dmg_all = ShaguDPS.view_dmg_all
local view_dps_all = ShaguDPS.view_dps_all
local dmg_table = ShaguDPS.dmg_table
local config = ShaguDPS.config
local round = ShaguDPS.round

local scroll = 0

local backdrop =  {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

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
    if attack ~= "_sum" and attack ~= "_ctime" and attack ~= "_tick" then
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
  this:SetBackdropBorderColor(1,.9,0,1)
end

local function btnLeave()
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

window.title = window:CreateTexture(nil, "NORMAL")
window.title:SetTexture(0,0,0,.6)
window.title:SetHeight(20)

window.btnDamage = CreateFrame("Button", "ShaguDPSDamage", window)
window.btnDamage:SetPoint("CENTER", window.title, "CENTER", -26, 0)
window.btnDamage:SetFrameStrata("MEDIUM")
window.btnDamage.caption = window.btnDamage:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
window.btnDamage.caption:SetText("Damage")
window.btnDamage.caption:SetAllPoints()
window.btnDamage:SetScript("OnEnter", btnEnter)
window.btnDamage:SetScript("OnLeave", btnLeave)
window.btnDamage:SetScript("OnClick", function()
  config.view = 1
  window.Refresh(true)
end)

window.btnDPS = CreateFrame("Button", "ShaguDPSDPS", window)
window.btnDPS:SetPoint("CENTER", window.title, "CENTER", 26, 0)
window.btnDPS:SetFrameStrata("MEDIUM")
window.btnDPS.caption = window.btnDPS:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
window.btnDPS.caption:SetText("DPS")
window.btnDPS.caption:SetAllPoints()
window.btnDPS:SetScript("OnEnter", btnEnter)
window.btnDPS:SetScript("OnLeave", btnLeave)
window.btnDPS:SetScript("OnClick", function()
  config.view = 2
  window.Refresh(true)
end)

window.btnReset = CreateFrame("Button", "ShaguDPSReset", window)
window.btnReset:SetPoint("RIGHT", window.title, "RIGHT", -4, 0)
window.btnReset:SetFrameStrata("MEDIUM")

window.btnReset.tex = window.btnReset:CreateTexture()
window.btnReset.tex:SetWidth(10)
window.btnReset.tex:SetHeight(10)
window.btnReset.tex:SetPoint("CENTER", 0, 0)
window.btnReset.tex:SetTexture("Interface\\AddOns\\ShaguDPS\\img\\reset")
window.btnReset:SetScript("OnEnter", btnEnter)
window.btnReset:SetScript("OnLeave", btnLeave)
window.btnReset:SetScript("OnClick", function()
  local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
  dialog.text = "Do you wish to reset the data?"
  dialog.OnAccept = function()
    -- clear overall damage data
    for k, v in pairs(dmg_table) do
      dmg_table[k] = nil
    end

    -- clear damage done
    for k, v in pairs(view_dmg_all) do
      view_dmg_all[k] = nil
    end

    -- clear dps
    for k, v in pairs(view_dmg_all) do
      view_dmg_all[k] = nil
    end

    -- reset scroll and reload
    scroll = 0
    window:Refresh()
  end
  StaticPopup_Show("SHAGUMETER_QUESTION")
end)

window.btnAnnounce = CreateFrame("Button", "ShaguDPSReset", window)
window.btnAnnounce:SetPoint("LEFT", window.title, "LEFT", 4, 0)
window.btnAnnounce:SetFrameStrata("MEDIUM")

window.btnAnnounce.tex = window.btnAnnounce:CreateTexture()
window.btnAnnounce.tex:SetWidth(10)
window.btnAnnounce.tex:SetHeight(10)
window.btnAnnounce.tex:SetPoint("CENTER", 0, 0)
window.btnAnnounce.tex:SetTexture("Interface\\AddOns\\ShaguDPS\\img\\announce")
window.btnAnnounce:SetScript("OnEnter", btnEnter)
window.btnAnnounce:SetScript("OnLeave", btnLeave)

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

  local view = config.view == 1 and view_dmg_all or view_dps_all
  local name = config.view == 1 and "Damage Done" or "Overall DPS"
  local text = "Post |cffffdd00" .. name .. "|r data into /" .. color..string.lower(ctype) .. "|r?"

  dialog.text = text
  dialog.OnAccept = function()
    -- load current maximum damage
    local best, all = window.GetCaps(view)
    if all <= 0 then return end

    -- announce all entries to chat
    announce("ShaguDPS - " .. name .. ":")
    local i = 1
    for name, damage in spairs(view, function(t,a,b) return t[b] < t[a] end) do
      if i <= 10 then
        announce(i .. ". " .. name .. " " .. damage .. " (" .. round(damage / all * 100,1) .. "%)")
      end
      i = i + 1
    end
  end
  StaticPopup_Show("SHAGUMETER_QUESTION")
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

window.GetCaps = function(view)
  local best, all = 0, 0
  for _, damage in pairs(view) do
    all = all + damage

    if damage > best then
      best = damage
    end
  end

  return best, all
end

window.Refresh = function(force)
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
    elseif config.view == 2 then
      window.btnDamage.caption:SetTextColor(.5,.5,.5,1)
      window.btnDPS.caption:SetTextColor(1,.9,0,1)
    end

    window:SetWidth(config.width)
    window:SetHeight(config.height * config.bars + 22 + 4)

    -- pfUI skin
    if config.pfui == 1 and pfUI and pfUI.uf and pfUI.api.CreateBackdrop then
      window.btnDamage:SetHeight(14)
      window.btnDamage:SetWidth(50)

      window.btnDPS:SetHeight(14)
      window.btnDPS:SetWidth(50)

      window.btnAnnounce:SetHeight(14)
      window.btnAnnounce:SetWidth(14)

      window.btnReset:SetHeight(14)
      window.btnReset:SetWidth(14)

      window.title:SetPoint("TOPLEFT", 1, -1)
      window.title:SetPoint("TOPRIGHT", -1, -1)

      pfUI.api.CreateBackdrop(window, nil, true, .75)
      pfUI.api.CreateBackdrop(window.btnAnnounce, nil, true, .75)
      pfUI.api.CreateBackdrop(window.btnReset, nil, true, .75)
      pfUI.api.CreateBackdrop(window.btnDamage, nil, true, .75)
      pfUI.api.CreateBackdrop(window.btnDPS, nil, true, .75)

      window.btnDamage:SetBackdropBorderColor(.4,.4,.4,1)
      window.btnDPS:SetBackdropBorderColor(.4,.4,.4,1)

      window.btnAnnounce:SetBackdropBorderColor(.4,.4,.4,1)
      window.btnReset:SetBackdropBorderColor(.4,.4,.4,1)

      window.border:Hide()
    else
      window.btnDamage:SetHeight(16)
      window.btnDamage:SetWidth(50)

      window.btnDPS:SetHeight(16)
      window.btnDPS:SetWidth(50)

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

      window.btnDamage:SetBackdrop(backdrop)
      window.btnDamage:SetBackdropColor(.2,.2,.2,1)
      window.btnDamage:SetBackdropBorderColor(.4,.4,.4,1)

      window.btnDPS:SetBackdrop(backdrop)
      window.btnDPS:SetBackdropColor(.2,.2,.2,1)
      window.btnDPS:SetBackdropBorderColor(.4,.4,.4,1)

      window.btnAnnounce:SetBackdrop(backdrop)
      window.btnAnnounce:SetBackdropColor(.2,.2,.2,1)
      window.btnAnnounce:SetBackdropBorderColor(.4,.4,.4,1)

      window.btnReset:SetBackdrop(backdrop)
      window.btnReset:SetBackdropColor(.2,.2,.2,1)
      window.btnReset:SetBackdropBorderColor(.4,.4,.4,1)

      window.border:Show()
    end
  end

  -- clear previous results
  for id, bar in pairs(window.bars) do
    bar:Hide()
  end

  -- load view and current maximum values
  local view = config.view == 1 and view_dmg_all or view_dps_all
  local best, all = window.GetCaps(view)

  local i = 1
  for name, damage in spairs(view, function(t,a,b) return t[b] < t[a] end) do
    local bar = i - scroll

    if bar >= 1 and bar <= config.bars then
      window.bars[bar] = not force and window.bars[bar] or CreateBar(window, bar)
      window.bars[bar]:SetMinMaxValues(0, best)
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
      window.bars[bar].textRight:SetText(damage .. " - " .. round(damage / all * 100,1) .. "%")
    end

    i = i + 1
  end
end

table.insert(parser.callbacks.refresh, window.Refresh)
