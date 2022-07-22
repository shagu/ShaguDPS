-- check for expansion
local tbc = ShaguDPS.expansion() == "tbc" and true or nil

-- all known classes
local classes = {
  WARRIOR = true, MAGE = true, ROGUE = true, DRUID = true, HUNTER = true,
  SHAMAN = true, PRIEST = true, WARLOCK = true, PALADIN = true,
}

--with border 
local setting_border = false
--with background
local setting_background = false

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

--healing extension variables
local parser2 = ShaguDPS.parser2
local view_heal_all = ShaguDPS.view_heal_all
local heal_table = ShaguDPS.heal_table

local scroll = 0

local backdrop =  {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
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
  if config.view == 1 then
    GameTooltip:AddDoubleLine("|cffffee00Damage Done", "|cffffffff" .. dmg_table[this.unit]["_sum"])
    GameTooltip:AddDoubleLine("|cffffee00DPS", "|cffffffff" .. view_dps_all[this.unit])
  elseif config.view == 2 then
    GameTooltip:AddDoubleLine("|cffffee00DPS", "|cffffffff" .. view_dps_all[this.unit])
    GameTooltip:AddDoubleLine("|cffffee00Damage Done", "|cffffffff" .. dmg_table[this.unit]["_sum"])
  elseif config.view == 3 then
    GameTooltip:AddDoubleLine("|cffffee00Heal Done", "|cffffffff" .. heal_table[this.unit]["_sum"][2] .. " - " ..view_heal_all[this.unit][1])
  end

  GameTooltip:AddLine(" ")
  if config.view == 1 or config.view == 2 then
	  for attack, damage in spairs(dmg_table[this.unit], function(t,a,b) return t[b] < t[a] end) do
		if attack ~= "_sum" and attack ~= "_ctime" and attack ~= "_tick" then
		  GameTooltip:AddDoubleLine("|cffffffff" .. attack, "|cffcccccc" .. damage .. " - |cffffffff" .. string.format("%.1f",round(damage / dmg_table[this.unit]["_sum"] * 100,1)) .. "%")
		end
	  end
  elseif config.view == 3 then
	for healspell, healamount in spairs(heal_table[this.unit], function(t,a,b) return t[b][1] < t[a][1] end) do
		if healspell ~= "_sum" and healspell ~= "_ctime" and healspell ~= "_tick" then
		  GameTooltip:AddDoubleLine("|cffffffff" .. healspell, "|cffcccccc" .. healamount[2] .." (|cffffffff" .. string.format("%.1f",round(healamount[2] / max(heal_table[this.unit]["_sum"][2],1) * 100,1)) .. "%) - " .. "|cffcccccc" .. healamount[1] .." (|cffffffff" .. string.format("%.1f",round(healamount[1] / heal_table[this.unit]["_sum"][1] * 100,1)) .. "%)")
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
  if config.view == 1 or config.view == 2 then
	  for k,v in pairs(view_dmg_all) do
		count = count + 1
	  end
  elseif config.view == 3 then
      for k,v in pairs(view_heal_all) do
		count = count + 1
	  end
  end
  scroll = math.min(scroll, count + 1 - config.bars)
  scroll = math.max(scroll, 0)

  window.Refresh()
end

local function CreateBar(parent, i)
  parent.bars[i] = parent.bars[i] or CreateFrame("StatusBar", "ShaguDPSBar" .. i, parent)
  parent.bars[i]:SetStatusBarTexture(textures[config.texture] or textures[1])

  --overhealing bars are plotted with a +1000 together with the effective healing bars
  local iminus = i
  if iminus>1000 then iminus=iminus-1000 end
  
  parent.bars[i]:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -config.height * (iminus-1) - 22)
  parent.bars[i]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -config.height * (iminus-1) - 22)
  parent.bars[i]:SetHeight(config.height)

  if i>1000 then 
    --plot the overhealing bar below the effective healing bar
    parent.bars[iminus]:SetFrameLevel(parent.bars[i]:GetFrameLevel()+1)
	return parent.bars[i] 
  end
  
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
if setting_background == true then 
	window:SetBackdrop({
	  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	  tile = true, tileSize = 16, edgeSize = 16,
	  insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	window:SetBackdropColor(.5,.5,.5,.5)
end

window.title = window:CreateTexture(nil, "NORMAL")
window.title:SetTexture(0,0,0,.6)
window.title:SetHeight(20)
window.title:SetPoint("TOPLEFT", 2, -2)
window.title:SetPoint("TOPRIGHT", -2, -2)

window.btnDamage = CreateFrame("Button", "ShaguDPSDamage", window)
window.btnDamage:SetPoint("CENTER", window.title, "CENTER", -26, 0)
window.btnDamage:SetFrameStrata("MEDIUM")
window.btnDamage:SetHeight(16)
window.btnDamage:SetWidth(50)
window.btnDamage:SetBackdrop(backdrop)
window.btnDamage:SetBackdropColor(.2,.2,.2,1)
window.btnDamage:SetBackdropBorderColor(.4,.4,.4,1)

window.btnDamage.caption = window.btnDamage:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
window.btnDamage.caption:SetFont(STANDARD_TEXT_FONT, 9)
window.btnDamage.caption:SetText("Damage")

window.btnDamage.caption:SetAllPoints()
window.btnDamage.tooltip = {
	"Toogle Views",
	{ "|cffffffffClick: Damage View", "|cffaaaaaaShows the overall damage done" },
	{ "|cffffffffShift-Click: Heal View", "|cffaaaaaaShows the overall heal done" },
}
window.btnDamage:SetScript("OnEnter", btnEnter)
window.btnDamage:SetScript("OnLeave", btnLeave)
window.btnDamage:SetScript("OnClick", function()
	if IsShiftKeyDown() then
	  config.view = 3
	  window.Refresh(true)
	else
	  config.view = 1
	  window.Refresh(true)
	end
end)

window.btnDPS = CreateFrame("Button", "ShaguDPSDPS", window)
window.btnDPS:SetPoint("CENTER", window.title, "CENTER", 26, 0)
window.btnDPS:SetFrameStrata("MEDIUM")
window.btnDPS:SetHeight(16)
window.btnDPS:SetWidth(50)
window.btnDPS:SetBackdrop(backdrop)
window.btnDPS:SetBackdropColor(.2,.2,.2,1)
window.btnDPS:SetBackdropBorderColor(.4,.4,.4,1)

window.btnDPS.caption = window.btnDPS:CreateFontString("ShaguDPSTitle", "OVERLAY", "GameFontWhite")
window.btnDPS.caption:SetFont(STANDARD_TEXT_FONT, 9)
window.btnDPS.caption:SetText("DPS")
window.btnDPS.caption:SetAllPoints()
window.btnDPS.tooltip = { "DPS View", "|cffffffffShows the overall DPS done" }
window.btnDPS:SetScript("OnEnter", btnEnter)
window.btnDPS:SetScript("OnLeave", btnLeave)
window.btnDPS:SetScript("OnClick", function()
  config.view = 2
  window.Refresh(true)
end)

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

local function ResetData()
  -- clear overall damage data
  for k, v in pairs(dmg_table) do
    dmg_table[k] = nil
  end

  -- clear damage done
  for k, v in pairs(view_dmg_all) do
    view_dmg_all[k] = nil
  end

  -- clear dps
  for k, v in pairs(view_dps_all) do
    view_dps_all[k] = nil
  end
  
  -- clear overall heal data
  for k, v in pairs(heal_table) do
    heal_table[k] = nil
  end

  -- clear heal done
  for k, v in pairs(view_heal_all) do
    view_heal_all[k] = nil
  end

  -- reset scroll and reload
  scroll = 0
  window:Refresh()
end

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
  ["PARTY"] = "|cffAAA0BC40",
  ["RAID"] = "|cffFF7DBFE",
  ["GUILD"] = "|cff3CE13F",
  ["OFFICER"] = "|cff401",
  ["RAID_WARNING"] = "|cffFF4700",
  ["BATTLEGROUND"] = "|cffFF7D01",
  ["WHISPER"] = "|cffFF7EFF",
  ["CHANNEL"] = "|cffFEC1C0"
}

local function AnnounceData()
  --local view = config.view == 1 and view_dmg_all or view_dps_all
  --local name = config.view == 1 and "Damage Done" or "Overall DPS"
  local view;
  local name;

  if config.view == 1 then
	view = view_dmg_all
	name = "Damage Done"
  elseif config.view == 2 then
	view = view_dps_all
	name = "Overall DPS"
  elseif config.view == 3 then
	view = view_heal_all
	name = "Heal Done"
  end

  -- load current maximum damage
  local best, all, all2 = window.GetCaps(view)
  if all <= 0 then return end

  -- announce all entries to chat
  announce("ShaguDPS - " .. name .. ":")
  local i = 1
  if config.view == 3 then
	for name, damage in spairs(view, function(t,a,b) return t[b][2] < t[a][2] end) do
		if i <= 10 then
		  announce(i .. ". " .. name .. " " .. damage[2] .." (" .. round(damage[2] / max(all2,1) * 100,1) .. "%)" .. " - " .. damage[1] .." (" .. round(damage[1] / all * 100,1) .. "%)")
		  --TODO overheal
		end
		i = i + 1
	end
  else
	for name, damage in spairs(view, function(t,a,b) return t[b] < t[a] end) do
		if i <= 10 then
		  announce(i .. ". " .. name .. " " .. damage .. " (" .. round(damage / all * 100,1) .. "%)")
		  --TODO overheal
		end
		i = i + 1
	end
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

    --local name = config.view == 1 and "Damage Done" or "Overall DPS"
	local name;
	if config.view == 1 then
		 name = "Damage Done"
	elseif config.view == 2 then
		 name = "Overall DPS"
	elseif config.view == 3 then
		 name = "Heal Done"
	end
	
    local text = "Post |cffffdd00" .. name .. "|r data into /" .. color..string.lower(ctype) .. "|r?"

    local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
    dialog.text = text
    dialog.OnAccept = AnnounceData
    StaticPopup_Show("SHAGUMETER_QUESTION")
  end
end)

if setting_border == true then 
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
end 

window.bars = {}

window.GetCaps = function(view)
  local best, all, all2 = 0, 0, 0
  for _, damage in pairs(view) do
    if config.view == 3 then
		all = all + damage[1] --total healing
		all2 = all2 + damage[2] --effective healing

		if damage[1] > best then
		  best = damage[1] --total healing best
		end
	else
		all = all + damage

		if damage > best then
		  best = damage
		end
	end
  end

  return best, all, all2
end

window.Refresh = function(force)
  -- config changes
  if force then
    if config.visible == 1 then
      window:Show()
    else
      window:Hide()
    end

    if config.view == 1 or config.view == 3 then
      window.btnDamage.caption:SetTextColor(1,.9,0,1)
      window.btnDPS.caption:SetTextColor(.5,.5,.5,1)
    elseif config.view == 2 then
      window.btnDamage.caption:SetTextColor(.5,.5,.5,1)
      window.btnDPS.caption:SetTextColor(1,.9,0,1)
    end
	
	if config.view == 3 then
		window.btnDamage.caption:SetText("Heal")
	else
		window.btnDamage.caption:SetText("Damage")
	end
	
    window:SetWidth(config.width)
    window:SetHeight(config.height * config.bars + 22 + 4)
  end

  -- clear previous results
  for id, bar in pairs(window.bars) do
    bar:Hide()
  end

  -- load view and current maximum values
  local view;
  if config.view == 1 then
	view = view_dmg_all
  elseif config.view == 2 then
	view = view_dps_all
  elseif config.view == 3 then
	view = view_heal_all
  end
  
  local best, all, all2 = window.GetCaps(view)

  local i = 1
  if config.view == 3 then
	for name, damage in spairs(view, function(t,a,b) return t[b][2] < t[a][2] end) do
		local bar = i - scroll

		if bar >= 1 and bar <= config.bars then
		  window.bars[bar] = not force and window.bars[bar] or CreateBar(window, bar)
		  
		  --plot the overhealing in grey as a bar+1000
		  window.bars[bar+1000] = not force and window.bars[bar+1000] or CreateBar(window, bar+1000)
		  window.bars[bar+1000]:SetMinMaxValues(0, best)
		  window.bars[bar+1000]:SetValue(damage[1])
		  window.bars[bar+1000]:Show()
		  window.bars[bar+1000]:SetAlpha(0.9)
		  window.bars[bar+1000]:SetStatusBarColor(0.5, 0.5, 0.5)
		  
		  window.bars[bar]:SetMinMaxValues(0, best)
		  window.bars[bar]:SetValue(damage[2])
		  window.bars[bar]:Show()
		  window.bars[bar].unit = name

		  local r, g, b = str2rgb(name)
		  local color = { r = r / 4 + .4, g = g / 4 + .4, b = b / 4 + .4 }
		
		  if classes[playerClasses[name]] then
			-- set color to player class colors
			color = RAID_CLASS_COLORS[playerClasses[name]]
		  end
			
		  window.bars[bar]:SetStatusBarColor(color.r, color.g, color.b)
		  window.bars[bar].textLeft:SetText(i .. ". " .. name)
		  window.bars[bar].textRight:SetText(damage[2] .. " - " .. damage[1])
		end

		i = i + 1
	end
  else
	  for name, damage in spairs(view, function(t,a,b) return t[b] < t[a] end) do
		local bar = i - scroll

		if bar >= 1 and bar <= config.bars then
		  window.bars[bar] = not force and window.bars[bar] or CreateBar(window, bar)
		  window.bars[bar]:SetMinMaxValues(0, best)
		  window.bars[bar]:SetValue(damage)
		  window.bars[bar]:Show()
		  window.bars[bar].unit = name

		  local r, g, b = str2rgb(name)
		  local color = { r = r / 4 + .4, g = g / 4 + .4, b = b / 4 + .4 }

		  if classes[playerClasses[name]] then
			-- set color to player class colors
			color = RAID_CLASS_COLORS[playerClasses[name]]
		  elseif playerClasses[name] ~= "__other__" then
			-- set color to player pet colors
			-- pets have their class set to the owners name
			local owner = playerClasses[name]
			if classes[playerClasses[owner]] then
			  color = RAID_CLASS_COLORS[playerClasses[owner]]
			  name = owner .. " - " .. name
			end
		  end

		  window.bars[bar]:SetStatusBarColor(color.r, color.g, color.b)
		  window.bars[bar].textLeft:SetText(i .. ". " .. name)
		  window.bars[bar].textRight:SetText(damage .. " - " .. round(damage / all * 100,1) .. "%")
		end

		i = i + 1
	  end
  end
end

table.insert(parser.callbacks.refresh, window.Refresh)
table.insert(parser2.callbacks.refresh, window.Refresh)
