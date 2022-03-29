local gfind = string.gmatch or string.gfind

StaticPopupDialogs["SHAGUMETER_QUESTION"] = {
  button1 = YES,
  button2 = NO,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

local textures = {
  "Interface\\BUTTONS\\WHITE8X8",
  "Interface\\TargetingFrame\\UI-StatusBar",
  "Interface\\Tooltips\\UI-Tooltip-Background",
  "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
}

local config = {
  -- size
  width = 150,
  height = 17,
  bars = 7,

  -- tracking
  track_all_units = 1,

  -- appearance
  visible = 1,
  texture = 2,
  pfui = 1,
}

local scroll = 0
local dmg_table = {}
local view_dmg_all = { }
local view_dmg_all_max = 0

local backdrop =  {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local playerClasses = {}

local validUnits = {}
validUnits["player"] = true
validUnits["pet"] = true

for i=1,4 do validUnits["party" .. i] = true end
for i=1,4 do validUnits["partypet" .. i] = true end
for i=1,40 do validUnits["raid" .. i] = true end
for i=1,40 do validUnits["raidpet" .. i] = true end

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

local meter = CreateFrame("Frame", "ShaguMeterGUI", UIParent)
local settings = CreateFrame("Frame")
local parser = CreateFrame("Frame")

do -- settings
  settings:RegisterEvent("PLAYER_ENTERING_WORLD")
  settings:SetScript("OnEvent", function()
    if ShaguMeter_Config then
      for k, v in pairs(ShaguMeter_Config) do
        -- print(k .. " -> " .. v)
        config[k] = v
      end
    end

    ShaguMeter_Config = config
    meter.Refresh(true)
  end)
end

do -- slashcmd
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
      return
    end

    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if strlower(cmd) == "visible" then
      if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
        config.visible = tonumber(args)
        ShaguMeter_Config = config
        meter:Refresh(true)
        p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Visible: " .. config.visible)
      else
        p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 0-1")
      end
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

      for source, v in pairs(playerClasses) do
        for i = 0, 20 do
          parser:AddData(source, "Auto Hit", UnitName("player"), floor(math.random()*500), "physical", true)
        end
      end

    elseif strlower(cmd) == "width" then
      if tonumber(args) then
        config.width = tonumber(args)
        ShaguMeter_Config = config
        meter:Refresh(true)

        p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Bar width: " .. config.width)
      else
        p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-999")
      end
    elseif strlower(cmd) == "height" then
      if tonumber(args) then
        config.height = tonumber(args)
        ShaguMeter_Config = config
        meter:Refresh(true)

        p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Bar height: " .. config.height)
      else
        p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-999")
      end
    elseif strlower(cmd) == "bars" then
      if tonumber(args) then
        config.bars = tonumber(args)
        ShaguMeter_Config = config
        meter:Refresh(true)

        p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Visible Bars: " .. config.bars)
      else
        p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-999")
      end
    elseif strlower(cmd) == "trackall" then
      if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
        config.track_all_units = tonumber(args)
        ShaguMeter_Config = config
        meter:Refresh(true)

        p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Track all units: " .. config.track_all_units)
      else
        p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 0-1")
      end
    elseif strlower(cmd) == "texture" then
      if tonumber(args) and textures[tonumber(args)] then
        config.texture = tonumber(args)
        ShaguMeter_Config = config
        meter:Refresh(true)

        p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc Texture: " .. config.texture)
      else
        p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 1-" .. table.getn(textures))
      end
    elseif strlower(cmd) == "pfui" then
      if tonumber(args) and (tonumber(args) == 1 or tonumber(args) == 0) then
        config.pfui = tonumber(args)
        ShaguMeter_Config = config
        meter:Refresh(true)
        p("|cffffcc00Shagu|cffffffffMeter:|cffffddcc pfUI theme: " .. config.pfui)
      else
        p("|cffffcc00Shagu|cffffffffMeter:|cffff5511 Valid Options are 0-1")
      end
    end
  end
end

do -- parser 1.12.1
  local function prepare(template)
    template = gsub(template, "%(", "%%(") -- fix ( in string
    template = gsub(template, "%)", "%%)") -- fix ) in string
    template = gsub(template, "%d%$","")
    template = gsub(template, "%%s", "(.+)")
    return gsub(template, "%%d", "(%%d+)")
  end

  -- me source me target
  local SPELLLOGSCHOOLSELFSELF = prepare(SPELLLOGSCHOOLSELFSELF) -- Your %s hits you for %d %s damage.
  local SPELLLOGCRITSCHOOLSELFSELF = prepare(SPELLLOGCRITSCHOOLSELFSELF) -- Your %s crits you for %d %s damage.
  local SPELLLOGSELFSELF = prepare(SPELLLOGSELFSELF) --Your %s hits you for %d.
  local SPELLLOGCRITSELFSELF = prepare(SPELLLOGCRITSELFSELF) -- Your %s crits you for %d.
  local PERIODICAURADAMAGESELFSELF =  prepare(PERIODICAURADAMAGESELFSELF) -- "You suffer %d %s damage from your %s.";

  -- me source
  local SPELLLOGSCHOOLSELFOTHER = prepare(SPELLLOGSCHOOLSELFOTHER) -- Your %s hits %s for %d %s damage.
  local SPELLLOGCRITSCHOOLSELFOTHER = prepare(SPELLLOGCRITSCHOOLSELFOTHER) -- Your %s crits %s for %d %s damage.
  local SPELLLOGSELFOTHER = prepare(SPELLLOGSELFOTHER) -- Your %s hits %s for %d.
  local SPELLLOGCRITSELFOTHER = prepare(SPELLLOGCRITSELFOTHER) -- Your %s crits %s for %d.
  local PERIODICAURADAMAGESELFOTHER = prepare(PERIODICAURADAMAGESELFOTHER) -- "%s suffers %d %s damage from your %s."; -- Rabbit suffers 3 frost damage from your Ice Nova.
  local COMBATHITSELFOTHER = prepare(COMBATHITSELFOTHER) -- You hit %s for %d.
  local COMBATHITCRITSELFOTHER = prepare(COMBATHITCRITSELFOTHER) -- You crit %s for %d.
  local COMBATHITSCHOOLSELFOTHER = prepare(COMBATHITSCHOOLSELFOTHER) -- You hit %s for %d %s damage.
  local COMBATHITCRITSCHOOLSELFOTHER = prepare(COMBATHITCRITSCHOOLSELFOTHER) -- You crit %s for %d %s damage.

  -- me target
  local SPELLLOGSCHOOLOTHERSELF = prepare(SPELLLOGSCHOOLOTHERSELF) -- %s's %s hits you for %d %s damage.
  local SPELLLOGCRITSCHOOLOTHERSELF = prepare(SPELLLOGCRITSCHOOLOTHERSELF) -- %s's %s crits you for %d %s damage.
  local SPELLLOGOTHERSELF = prepare(SPELLLOGOTHERSELF) -- %s's %s hits you for %d.
  local SPELLLOGCRITOTHERSELF = prepare(SPELLLOGCRITOTHERSELF) -- %s's %s crits you for %d.
  local PERIODICAURADAMAGEOTHERSELF = prepare(PERIODICAURADAMAGEOTHERSELF) -- "You suffer %d %s damage from %s's %s."; -- You suffer 3 frost damage from Rabbit's Ice Nova.
  local COMBATHITOTHERSELF = prepare(COMBATHITOTHERSELF) -- %s hits you for %d.
  local COMBATHITCRITOTHERSELF = prepare(COMBATHITCRITOTHERSELF) -- %s crits you for %d.
  local COMBATHITSCHOOLOTHERSELF = prepare(COMBATHITSCHOOLOTHERSELF) -- %s hits you for %d %s damage.
  local COMBATHITCRITSCHOOLOTHERSELF = prepare(COMBATHITCRITSCHOOLOTHERSELF) -- %s crits you for %d %s damage.

  -- other
  local SPELLLOGSCHOOLOTHEROTHER = prepare(SPELLLOGSCHOOLOTHEROTHER) -- %s's %s hits %s for %d %s damage.
  local SPELLLOGCRITSCHOOLOTHEROTHER = prepare(SPELLLOGCRITSCHOOLOTHEROTHER) -- %s's %s crits %s for %d %s damage.
  local SPELLLOGOTHEROTHER = prepare(SPELLLOGOTHEROTHER) -- %s's %s hits %s for %d.
  local SPELLLOGCRITOTHEROTHER = prepare(SPELLLOGCRITOTHEROTHER) -- %s's %s crits %s for %d.
  local PERIODICAURADAMAGEOTHEROTHER = prepare(PERIODICAURADAMAGEOTHEROTHER) -- "%s suffers %d %s damage from %s's %s."; -- Bob suffers 5 frost damage from Jeff's Ice Nova.
  local COMBATHITOTHEROTHER = prepare(COMBATHITOTHEROTHER) -- %s hits %s for %d.
  local COMBATHITCRITOTHEROTHER = prepare(COMBATHITCRITOTHEROTHER) -- %s crits %s for %d.
  local COMBATHITSCHOOLOTHEROTHER = prepare(COMBATHITSCHOOLOTHEROTHER) -- %s hits %s for %d %s damage.
  local COMBATHITCRITSCHOOLOTHEROTHER = prepare(COMBATHITCRITSCHOOLOTHEROTHER) -- %s crits %s for %d %s damage.

  parser.callbacks = {
    ["refresh"] = {}
  }

  parser.ScanName = function(self, name)
    for unit, _ in pairs(validUnits) do
      if UnitExists(unit) and UnitName(unit) == name then
        if UnitIsPlayer(unit) then
          local _, class = UnitClass(unit)
          playerClasses[name] = class
          return true
        else
          playerClasses[name] = unit
          return true
        end
      end
    end

    if config.track_all_units == 1 then
      playerClasses[name] = playerClasses[name] or "other"
      return true
    else
      return false
    end
  end

  parser.AddData = function(self, source, attack, target, damage, school, force)
    -- Debug:
    -- DEFAULT_CHAT_FRAME:AddMessage(source .. " (" .. attack .. ") -> " .. target .. ": " .. damage .. " (" .. (school or "nil") .. ")")

    -- write dmg_table table
    if not dmg_table[source] and ( parser:ScanName(source) or force ) then
      dmg_table[source] = {}
    end

    if dmg_table[source] then
      dmg_table[source][attack] = (dmg_table[source][attack] or 0) + tonumber(damage)
      dmg_table[source]["_sum"] = (dmg_table[source]["_sum"] or 0) + tonumber(damage)
    else
      return
    end

    if dmg_table[source] then
      view_dmg_all[source] = (view_dmg_all[source] or 0) + tonumber(damage)
    end

    for id, callback in pairs(parser.callbacks.refresh) do
      callback(source)
    end
  end

  local datasources = {
    --[[ me source me target ]]--
    -- Your %s hits you for %d %s damage.
    function(source, target, school, attack)
      for attack, damage, school in string.gfind(arg1, SPELLLOGSCHOOLSELFSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- Your %s crits you for %d %s damage.
    function(source, target, school, attack)
      for attack, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLSELFSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- Your %s hits you for %d.
    function(source, target, school, attack)
      for attack, damage in string.gfind(arg1, SPELLLOGSELFSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- Your %s crits you for %d.
    function(source, target, school, attack)
      for attack, damage in string.gfind(arg1, SPELLLOGCRITSELFSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- "You suffer %d %s damage from your %s.";
    function(source, target, school, attack)
      for damage, school, attack in string.gfind(arg1, PERIODICAURADAMAGESELFSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    --[[ me source ]]--
    -- Your %s hits %s for %d %s damage.
    function(source, target, school, attack)
      for attack, target, damage, school in string.gfind(arg1, SPELLLOGSCHOOLSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- Your %s crits %s for %d %s damage.
    function(source, target, school, attack)
      for attack, target, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- Your %s hits %s for %d.
    function(source, target, school, attack)
      for attack, target, damage in string.gfind(arg1, SPELLLOGSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- Your %s crits %s for %d.
    function(source, target, school, attack)
      for attack, target, damage in string.gfind(arg1, SPELLLOGCRITSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s suffers %d %s damage from your %s.";
    -- Rabbit suffers 3 frost damage from your Ice Nova.
    function(source, target, school, attack)
      for target, damage, school, attack in string.gfind(arg1, PERIODICAURADAMAGESELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- You hit %s for %d.
    function(source, target, school, attack)
      for target, damage in string.gfind(arg1, COMBATHITSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- You crit %s for %d.
    function(source, target, school, attack)
      for target, damage in string.gfind(arg1, COMBATHITCRITSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- You hit %s for %d %s damage.
    function(source, target, school, attack)
      for target, damage, school in string.gfind(arg1, COMBATHITSCHOOLSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- You crit %s for %d %s damage.
    function(source, target, school, attack)
      for target, damage, school in string.gfind(arg1, COMBATHITCRITSCHOOLSELFOTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    --[[ me target ]]--
    -- %s's %s hits you for %d %s damage.
    function(source, target, school, attack)
      for source, attack, damage, school in string.gfind(arg1, SPELLLOGSCHOOLOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s's %s crits you for %d %s damage.
    function(source, target, school, attack)
      for source, attack, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s's %s hits you for %d.
    function(source, target, school, attack)
      for source, attack, damage in string.gfind(arg1, SPELLLOGOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s's %s crits you for %d.
    function(source, target, school, attack)
      for source, attack, damage in string.gfind(arg1, SPELLLOGCRITOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- "You suffer %d %s damage from %s's %s.";
    -- You suffer 3 frost damage from Rabbit's Ice Nova.
    function(source, target, school, attack)
      for damage, school, source, attack in string.gfind(arg1, PERIODICAURADAMAGEOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s hits you for %d.
    function(source, target, school, attack)
      for source, damage in string.gfind(arg1, COMBATHITOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s crits you for %d.
    function(source, target, school, attack)
      for source, damage in string.gfind(arg1, COMBATHITCRITOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s hits you for %d %s damage.
    function(source, target, school, attack)
      for source, damage, school in string.gfind(arg1, COMBATHITSCHOOLOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s crits you for %d %s damage.
    function(source, target, school, attack)
      for source, damage, school in string.gfind(arg1, COMBATHITCRITSCHOOLOTHERSELF) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    --[[ other ]]--
    -- %s's %s hits %s for %d %s damage.
    function(source, target, school, attack)
      for source, attack, target, damage, school in string.gfind(arg1, SPELLLOGSCHOOLOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s's %s crits %s for %d %s damage.
    function(source, target, school, attack)
      for source, attack, target, damage, school in string.gfind(arg1, SPELLLOGCRITSCHOOLOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s's %s hits %s for %d.
    function(source, target, school, attack)
      for source, attack, target, damage in string.gfind(arg1, SPELLLOGOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s's %s crits %s for %d.
    function(source, target, school, attack)
      for source, attack, target, damage, school in string.gfind(arg1, SPELLLOGCRITOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- "%s suffers %d %s damage from %s's %s.";
    -- Bob suffers 5 frost damage from Jeff's Ice Nova.
    function(source, target, school, attack)
      for target, damage, school, source, attack in string.gfind(arg1, PERIODICAURADAMAGEOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s hits %s for %d.
    function(source, target, school, attack)
      for source, target, damage in string.gfind(arg1, COMBATHITOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s crits %s for %d.
    function(source, target, school, attack)
      for source, target, damage in string.gfind(arg1, COMBATHITCRITOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s hits %s for %d %s damage.
    function(source, target, school, attack)
      for source, target, damage, school in string.gfind(arg1, COMBATHITSCHOOLOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,

    -- %s crits %s for %d %s damage.
    function(source, target, school, attack)
      for source, target, damage, school in string.gfind(arg1, COMBATHITCRITSCHOOLOTHEROTHER) do
        parser:AddData(source, attack, target, damage, school)
        return true
      end
    end,
  }

  parser:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_PARTY_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS")
  parser:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
  parser:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
  parser:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")
  parser:SetScript("OnEvent", function()
    if not arg1 then return end

    local source = UnitName("player")
    local target = UnitName("player")
    local school = "physical"
    local attack = "Auto Hit"

    -- detection on all data sources
    for id, func in pairs(datasources) do
      if func(source, target, school, attack) then
        return
      end
    end
  end)
end

do -- meter
  local function barTooltipShow()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:AddDoubleLine("|cff33ffccDamage Done", "|cffffffff" .. dmg_table[this.unit]["_sum"])
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

    meter.Refresh()
  end

  local function CreateBar(parent, i)
    parent.bars[i] = parent.bars[i] or CreateFrame("StatusBar", "ShaguMeterBar" .. i, parent)
    parent.bars[i]:SetStatusBarTexture(textures[config.texture] or textures[1])

    parent.bars[i]:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -config.height * (i-1) - 22)
    parent.bars[i]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -config.height * (i-1) - 22)
    parent.bars[i]:SetHeight(config.height)

    parent.bars[i].textLeft = parent.bars[i].textLeft or parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
    parent.bars[i].textLeft:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    parent.bars[i].textLeft:SetJustifyH("LEFT")
    parent.bars[i].textLeft:SetFontObject(GameFontWhite)
    parent.bars[i].textLeft:SetParent(parent.bars[i])
    parent.bars[i].textLeft:ClearAllPoints()
    parent.bars[i].textLeft:SetPoint("TOPLEFT", parent.bars[i], "TOPLEFT", 5, 1)
    parent.bars[i].textLeft:SetPoint("BOTTOMRIGHT", parent.bars[i], "BOTTOMRIGHT", -5, 0)

    parent.bars[i].textRight = parent.bars[i].textRight or parent.bars[i]:CreateFontString("Status", "OVERLAY", "GameFontNormal")
    parent.bars[i].textRight:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
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

  meter:ClearAllPoints()
  meter:SetPoint("RIGHT", UIParent, "RIGHT", -100, -100)

  meter:EnableMouse(true)
  meter:EnableMouseWheel(1)
  meter:RegisterForDrag("LeftButton")
  meter:SetMovable(true)
  meter:SetUserPlaced(true)
  meter:SetScript("OnDragStart", function() meter:StartMoving() end)
  meter:SetScript("OnDragStop", function() meter:StopMovingOrSizing() end)
  meter:SetScript("OnMouseWheel", barScrollWheel)
  meter:SetClampedToScreen(true)

  meter.title = meter:CreateTexture(nil, "NORMAL")
  meter.title:SetTexture(0,0,0,.6)
  meter.title:SetHeight(20)

  meter.titleText = meter:CreateFontString("ShaguMeterTitle", "OVERLAY", "GameFontWhite")
  meter.titleText:SetAllPoints(meter.title)
  meter.titleText:SetText("ShaguMeter")

  meter.btnReset = CreateFrame("Button", "ShaguMeterReset", meter)
  meter.btnReset:SetPoint("RIGHT", meter.title, "RIGHT", -4, 0)
  meter.btnReset:SetFrameStrata("MEDIUM")

  meter.btnReset.tex = meter.btnReset:CreateTexture()
  meter.btnReset.tex:SetWidth(10)
  meter.btnReset.tex:SetHeight(10)
  meter.btnReset.tex:SetPoint("CENTER", 0, 0)
  meter.btnReset.tex:SetTexture("Interface\\AddOns\\ShaguMeter\\img\\reset")
  meter.btnReset:SetScript("OnEnter", function()
    this:SetBackdropBorderColor(1,.9,0,1)
  end)

  meter.btnReset:SetScript("OnLeave", function()
    this:SetBackdropBorderColor(.4,.4,.4,1)
  end)

  meter.btnReset:SetScript("OnClick", function()
    local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
    dialog.text = "Do you wish to reset the data?"
    dialog.OnAccept = function()
      dmg_table = {}
      view_dmg_all = {}
      view_dmg_all_max = 0
      scroll = 0
      meter:Refresh()
    end
    StaticPopup_Show("SHAGUMETER_QUESTION")
  end)

  meter.btnAnnounce = CreateFrame("Button", "ShaguMeterReset", meter)
  meter.btnAnnounce:SetPoint("LEFT", meter.title, "LEFT", 4, 0)
  meter.btnAnnounce:SetFrameStrata("MEDIUM")

  meter.btnAnnounce.tex = meter.btnAnnounce:CreateTexture()
  meter.btnAnnounce.tex:SetWidth(10)
  meter.btnAnnounce.tex:SetHeight(10)
  meter.btnAnnounce.tex:SetPoint("CENTER", 0, 0)
  meter.btnAnnounce.tex:SetTexture("Interface\\AddOns\\ShaguMeter\\img\\announce")
  meter.btnAnnounce:SetScript("OnEnter", function()
    this:SetBackdropBorderColor(1,.9,0,1)
  end)

  meter.btnAnnounce:SetScript("OnLeave", function()
    this:SetBackdropBorderColor(.4,.4,.4,1)
  end)

  meter.btnAnnounce:SetScript("OnClick", function()
    local dialog = StaticPopupDialogs["SHAGUMETER_QUESTION"]
    dialog.text = "Post damage data into chat?"
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

      SendChatMessage("ShaguMeter - Damage Done:")
      local i = 1
      for name, damage in spairs(view_dmg_all, function(t,a,b) return t[b] < t[a] end) do
        if i <= 5 then
          SendChatMessage(i .. ". " .. name .. ": " .. damage .. " (" .. round(damage / sum_dmg * 100,1) .. "%)")
        end
        i = i + 1
      end
    end
    StaticPopup_Show("SHAGUMETER_QUESTION")
  end)

  meter.border = CreateFrame("Frame", "ShaguMeterBorder", ShaguMeter)
  meter.border:ClearAllPoints()
  meter.border:SetPoint("TOPLEFT", meter, "TOPLEFT", -1,1)
  meter.border:SetPoint("BOTTOMRIGHT", meter, "BOTTOMRIGHT", 1,-1)
  meter.border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  meter.border:SetBackdropBorderColor(.7,.7,.7,1)
  meter.border:SetFrameLevel(100)

  meter.bars = {}

  meter.Refresh = function(force)
    -- config changes
    if force then
      meter:SetWidth(config.width)
      meter:SetHeight(config.height * config.bars + 22 + 4)

      -- pfUI skin
      if config.pfui == 1 and pfUI.uf and pfUI.api.CreateBackdrop then
        meter.btnAnnounce:SetHeight(14)
        meter.btnAnnounce:SetWidth(14)

        meter.btnReset:SetHeight(14)
        meter.btnReset:SetWidth(14)

        meter.title:SetPoint("TOPLEFT", 1, -1)
        meter.title:SetPoint("TOPRIGHT", -1, -1)

        pfUI.api.CreateBackdrop(meter, nil, true, .75)
        pfUI.api.CreateBackdrop(meter.btnAnnounce, nil, true, .75)
        pfUI.api.CreateBackdrop(meter.btnReset, nil, true, .75)

        meter.btnAnnounce:SetBackdropBorderColor(.4,.4,.4,1)
        meter.btnReset:SetBackdropBorderColor(.4,.4,.4,1)

        meter.border:Hide()
      else
        meter.btnAnnounce:SetHeight(16)
        meter.btnAnnounce:SetWidth(16)

        meter.btnReset:SetHeight(16)
        meter.btnReset:SetWidth(16)

        meter.title:SetPoint("TOPLEFT", 2, -2)
        meter.title:SetPoint("TOPRIGHT", -2, -2)

        meter:SetBackdrop({
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
          tile = true, tileSize = 16, edgeSize = 16,
          insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        meter:SetBackdropColor(.5,.5,.5,.5)

        meter.btnAnnounce:SetBackdrop(backdrop)
        meter.btnAnnounce:SetBackdropColor(.2,.2,.2,1)
        meter.btnAnnounce:SetBackdropBorderColor(.4,.4,.4,1)

        meter.btnReset:SetBackdrop(backdrop)
        meter.btnReset:SetBackdropColor(.2,.2,.2,1)
        meter.btnReset:SetBackdropBorderColor(.4,.4,.4,1)

        meter.border:Show()
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
    for id, bar in pairs(meter.bars) do
      bar:Hide()
    end

    local i = 1
    for name, damage in spairs(view_dmg_all, function(t,a,b) return t[b] < t[a] end) do
      local bar = i - scroll

      if bar >= 1 and bar <= config.bars then
        meter.bars[bar] = not force and meter.bars[bar] or CreateBar(meter, bar)
        meter.bars[bar]:SetMinMaxValues(0, view_dmg_all_max)
        meter.bars[bar]:SetValue(damage)
        meter.bars[bar]:Show()
        meter.bars[bar].unit = name

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

        meter.bars[bar]:SetStatusBarColor(color.r, color.g, color.b)

        meter.bars[bar].textLeft:SetText(i .. ". " .. name)
        meter.bars[bar].textRight:SetText(damage .. " - " .. round(damage / sum_dmg * 100,1) .. "%")
      end

      i = i + 1
    end
  end

  table.insert(parser.callbacks.refresh, meter.Refresh)
end
