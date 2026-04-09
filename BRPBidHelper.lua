-- ============================================================
-- CONFIGURATION: change raid labels to match your guild
-- ============================================================
local RAID1_LABEL = "NAXX"   -- first number in officer note  {RAID1:RAID2}
local RAID2_LABEL = "KARA"   -- second number in officer note {RAID1:RAID2}
-- ============================================================

local state = {
  weird_vibes_mode = true,
  rollMessages = {},
  rollers = {},
  isRolling = false,
  time_elapsed = 0,
  item_query = 0.5,
  times = 5,
  discover = CreateFrame("GameTooltip", "CustomTooltip1", UIParent, "GameTooltipTemplate"),
  masterLooter = nil,
  srRollCap = 101,
  msRollCap = 100,
  osRollCap = 99,
  tmogRollCap = 98,
  minimumBid = "10",
  naxx = 0,
  kara = 0,
}

StaticPopupDialogs["CONFIRM_ALL_IN_NAXX"] = {
  text = "Are you sure ebashish " .. RAID1_LABEL .. " DKP?",
  button1 = "Yes",
  button2 = "Ne Ne Ne",
  OnAccept = function()
      SendChatMessage(state.naxx, "WHISPER", nil, state.masterLooter)
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["CONFIRM_ALL_IN_KARA"] = {
  text = "Are you sure ebashish " .. RAID2_LABEL .. " DKP?",
  button1 = "Yes",
  button2 = "Ne Ne Ne",
  OnAccept = function()
      SendChatMessage(state.kara, "WHISPER", nil, state.masterLooter)
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local FRAME_WIDTH = 300
local BUTTON_HEIGHT = 32
local BUTTON_PADDING = 5
local FONT_NAME = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 12
local FONT_OUTLINE = "OUTLINE"
local RAID_CLASS_COLORS = {
  ["Warrior"] = "FFC79C6E",
  ["Mage"]    = "FF69CCF0",
  ["Rogue"]   = "FFFFF569",
  ["Druid"]   = "FFFF7D0A",
  ["Hunter"]  = "FFABD473",
  ["Shaman"]  = "FF0070DE",
  ["Priest"]  = "FFFFFFFF",
  ["Warlock"] = "FF9482C9",
  ["Paladin"] = "FFF58CBA",
}
local colors = {
  ADDON_TEXT_COLOR = "FFEDD8BB",
  DEFAULT_TEXT_COLOR = "FFFFFF00",
  SR_TEXT_COLOR = "ffe5302d",
  MS_TEXT_COLOR = "FFFFFF00",
  OS_TEXT_COLOR = "FF00FF00",
  TM_TEXT_COLOR = "FF00FFFF",
  OTHER_TEXT_COLOR = "ffff80be",
}

local LB_PREFIX = "BRPBT"
local LB_GET_DATA = "get data"
local LB_SET_ML = "ML set to "

local function lb_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|c" .. colors.ADDON_TEXT_COLOR .. "BRPBidHelper: " .. msg .. "|r")
end

local function resetRolls()
  state.rollMessages = {}
  state.rollers = {}
end

local function sortRolls()
  table.sort(state.rollMessages, function(a, b)
    return a.bid > b.bid
  end)
end

local function formatMsg(message)
  local class = message.class
  local classColor = RAID_CLASS_COLORS[class]
  local textColor = colors.DEFAULT_TEXT_COLOR

  local c_class = format("|c%s%s|r", classColor, message.bidder)
  local c_rank = message.bidderRank and format(" (%s)", message.bidderRank) or ""
  local c_note = message.note and format(" %s", message.note) or ""
  local c_bid = format(" |c%s%-3s|r", textColor, message.bid)

  return c_class .. c_rank .. c_note .. c_bid
end

local function tsize(t)
  c = 0
  for _ in pairs(t) do
    c = c + 1
  end
  if c > 0 then return c else return nil end
end

local function IsInRaid()
  return GetNumRaidMembers() > 0
end

local function IsInGroup()
  return GetNumPartyMembers() + GetNumRaidMembers() > 0
end

local function CheckItem(link)
  state.discover:SetOwner(UIParent, "ANCHOR_PRESERVE")
  state.discover:SetHyperlink(link)

  if discoverTextLeft1 and discoverTooltipTextLeft1:IsVisible() then
    local name = discoverTooltipTextLeft1:GetText()
    discoverTooltip:Hide()

    if name == (RETRIEVING_ITEM_INFO or "") then
      return false
    else
      return true
    end
  end
  return false
end

local function CreateCloseButton(frame)
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetWidth(32)
  closeButton:SetHeight(32)
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

  closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
  closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
  closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")

  closeButton:SetScript("OnClick", function()
      frame:Hide()
      resetRolls()
  end)
end

-- Calculate X offset for button at `index` in a row of `total` buttons of `width`
local function ButtonRowX(index, total, width)
  local spacing = (FRAME_WIDTH - total * width) / (total + 1)
  return spacing + (index - 1) * (width + spacing)
end

-- Unified button factory (BOTTOMLEFT anchor)
local function CreateButton(frame, buttonText, tooltipText, x, y, width, onClickAction)
  local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(BUTTON_HEIGHT)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, y)
  button:SetText(buttonText)
  button:GetFontString():SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  if tooltipText then
    button:SetScript("OnEnter", function()
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  button:SetScript("OnClick", onClickAction)
  return button
end

local function CreateInputFrame(frame)
  local editBox = CreateFrame("EditBox", "MyAddonEditBox", frame, "InputBoxTemplate")
  editBox:SetWidth(110)
  editBox:SetHeight(32)
  editBox:SetPoint("BOTTOM", frame, "BOTTOM", -65, 80)
  editBox:SetAutoFocus(false)
  editBox:SetText("10")

  editBox:SetScript("OnEnterPressed", function()
    editBox:ClearFocus()
  end)

  editBox:SetScript("OnHide", function()
    editBox:SetText("10")
  end)

  local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
  button:SetWidth(50)
  button:SetHeight(30)
  button:SetPoint("BOTTOM", frame, "BOTTOM", 37, 80)
  button:SetText("Bid")
  button:GetFontString():SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  button:SetScript("OnClick", function()
    SendChatMessage(editBox:GetText(), "WHISPER", nil, state.masterLooter)
  end)
end

local function CreateItemRollFrame()
  local frame = CreateFrame("Frame", "ItemRollFrame", UIParent)
  frame:SetWidth(FRAME_WIDTH)
  frame:SetHeight(260)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 1)

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() frame:StartMoving() end)
  frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

  CreateCloseButton(frame)
  CreateInputFrame(frame)

  -- Row 1 (bottom): ALL IN NAXX / ALL IN KARA
  local allInY = BUTTON_PADDING
  local allInW = 120
  CreateButton(frame, "ALL IN " .. RAID1_LABEL, "Bid ALL IN " .. RAID1_LABEL .. " DKP",
    ButtonRowX(1, 2, allInW), allInY, allInW,
    function() StaticPopup_Show("CONFIRM_ALL_IN_NAXX") end)
  CreateButton(frame, "ALL IN " .. RAID2_LABEL, "Bid ALL IN " .. RAID2_LABEL .. " DKP",
    ButtonRowX(2, 2, allInW), allInY, allInW,
    function() StaticPopup_Show("CONFIRM_ALL_IN_KARA") end)

  -- Row 2: Roll MS / Roll OS / Roll TMOG
  local rollY = BUTTON_PADDING + BUTTON_HEIGHT + BUTTON_PADDING
  local rollW = 88
  CreateButton(frame, "Roll MS", "Roll for Main Spec (1-" .. state.msRollCap .. ")",
    ButtonRowX(1, 3, rollW), rollY, rollW,
    function() RandomRoll(1, state.msRollCap) end)
  CreateButton(frame, "Roll OS", "Roll for Off Spec (1-" .. state.osRollCap .. ")",
    ButtonRowX(2, 3, rollW), rollY, rollW,
    function() RandomRoll(1, state.osRollCap) end)
  CreateButton(frame, "Roll TMOG", "Roll for Transmog (1-" .. state.tmogRollCap .. ")",
    ButtonRowX(3, 3, rollW), rollY, rollW,
    function() RandomRoll(1, state.tmogRollCap) end)

  frame:Hide()
  return frame
end

local itemRollFrame = CreateItemRollFrame()

local function InitItemInfo(frame)
  local icon = frame:CreateTexture()
  icon:SetWidth(40)
  icon:SetHeight(40)
  icon:SetPoint("TOP", frame, "TOP", 0, -10)

  local iconButton = CreateFrame("Button", nil, frame)
  iconButton:SetWidth(40)
  iconButton:SetHeight(40)
  iconButton:SetPoint("TOP", frame, "TOP", 0, -10)

  local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  timerText:SetPoint("CENTER", frame, "TOPLEFT", 30, -32)
  timerText:SetFont(timerText:GetFont(), 20)

  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("TOP", icon, "BOTTOM", 0, -2)

  frame.icon = icon
  frame.iconButton = iconButton
  frame.timerText = timerText
  frame.name = name
  frame.itemLink = ""

  local tt = CreateFrame("GameTooltip", "CustomTooltip2", UIParent, "GameTooltipTemplate")

  iconButton:SetScript("OnEnter", function()
    tt:SetOwner(iconButton, "ANCHOR_RIGHT")
    tt:SetHyperlink(frame.itemLink)
    tt:Show()
  end)
  iconButton:SetScript("OnLeave", function()
    tt:Hide()
  end)
  iconButton:SetScript("OnClick", function()
    if IsControlKeyDown() then
      DressUpItemLink(frame.itemLink)
    elseif IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
      local itemName, itemLink, itemQuality = GetItemInfo(frame.itemLink)
      ChatFrameEditBox:Insert(ITEM_QUALITY_COLORS[itemQuality].hex.."\124H"..itemLink.."\124h["..itemName.."]\124h"..FONT_COLOR_CODE_CLOSE)
    end
  end)
end

local function GetColoredTextByQuality(text, qualityIndex)
  local r, g, b, hex = GetItemQualityColor(qualityIndex)
  return string.format("%s%s|r", hex, text)
end

local function SetItemInfo(frame, itemLinkArg)
  local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(itemLinkArg)
  if not frame.icon then InitItemInfo(frame) end

  if itemName and itemQuality < 2 then return false end
  if not itemIcon then
    frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.name:SetText("Unknown item, attempting to query...")
    return true
  end

  frame.icon:SetTexture(itemIcon)
  frame.iconButton:SetNormalTexture(itemIcon)
  frame.name:SetText(GetColoredTextByQuality(itemName, itemQuality))
  frame.itemLink = itemLink
  return true
end

local function ShowFrame(frame, duration, item)
  frame:SetScript("OnUpdate", function()
    state.time_elapsed = state.time_elapsed + arg1
    state.item_query = state.item_query - arg1
    local delta = duration - state.time_elapsed
    if frame.timerText then frame.timerText:SetText(format("%.1f", delta > 0 and delta or 0)) end
    if state.time_elapsed >= max(duration, FrameShownDuration) then
      frame.timerText:SetText("0.0")
      frame:SetScript("OnUpdate", nil)
      state.time_elapsed = 0
      state.item_query = 1.5
      state.times = 3
      state.rollMessages = {}
      state.isRolling = false
      if FrameAutoClose and not (state.masterLooter == UnitName("player")) then frame:Hide() end
    end
    if state.times > 0 and state.item_query < 0 and not CheckItem(item) then
      state.times = state.times - 1
    else
      if not SetItemInfo(itemRollFrame, item) then frame:Hide() end
      state.times = 5
    end
  end)
  frame:Show()
end

local function CreateTextArea(frame)
  local textArea = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textArea:SetFont("Interface\\AddOns\\BRPBidHelper\\MonaspaceNeonFrozen-Regular.ttf", 12, "")
  textArea:SetHeight(100)
  textArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -70)
  textArea:SetJustifyH("LEFT")
  textArea:SetJustifyV("TOP")
  return textArea
end

local function GetClassOfRoller(rollerName)
  for i = 1, GetNumRaidMembers() do
    local name, rank, subgroup, level, class = GetRaidRosterInfo(i)
    if name == rollerName then
      return class
    end
  end
  return nil
end

function getPlayerRank(playerName)
  for i = 1, GetNumGuildMembers() do
    local name, rankName, rankIndex, _, _, _, _, note = GetGuildRosterInfo(i)
    if name == playerName then
      return rankName, note
    end
  end
  return "none", "{}"
end

local function UpdateTextArea(frame)
  if not frame.textArea then
    frame.textArea = CreateTextArea(frame)
  end

  local masterLooterName = state.masterLooter or "Unknown"
  local text = "Current Master Looter: " .. masterLooterName .. "\n\n"

  local bidderRank, note = getPlayerRank(UnitName("player"))

  local _, _, ep = string.find(note, "{(%d+):%d+}")
  local _, _, gp = string.find(note, "{%d+:(%d+)}")

  -- Guard against missing DKP in officer note
  ep = ep or "0"
  gp = gp or "0"

  state.naxx = ep
  state.kara = gp

  text = text .. "Your Rank: " .. bidderRank .. "\n"
  text = text .. "Your " .. RAID1_LABEL .. " DKP: " .. ep .. "\n"
  text = text .. "Your " .. RAID2_LABEL .. " DKP: " .. gp

  frame.textArea:SetText(text)
end

local function ExtractItemLinksFromMessage(message)
  local itemLinks = {}
  for link in string.gfind(message, "|c.-|H(item:.-)|h.-|h|r") do
    table.insert(itemLinks, link)
  end
  return itemLinks
end

local function IsAwardAnnouncement(message)
  return string.find(message, " wins ") and
    string.find(message, " for ") and
    string.find(message, " DKP")
end

local function GetMasterLooterInParty()
  local lootMethod, masterLooterPartyID = GetLootMethod()
  if lootMethod == "master" and masterLooterPartyID then
    if masterLooterPartyID == 0 then
      return UnitName("player")
    else
      return UnitName("party" .. masterLooterPartyID)
    end
  end
  return nil
end

local function PlayerIsML()
  local lootMethod, masterLooterPartyID = GetLootMethod()
  return lootMethod == "master" and masterLooterPartyID and (masterLooterPartyID == 0)
end

local pendingRequest, requestDelay = false, 0
local pendingSet, setDelay, setName = false, 0.5, ""
local function RequestML(delay)
  pendingRequest = true
  requestDelay   = delay or 3.0
end

local delayFrame = CreateFrame("Frame")
delayFrame:SetScript("OnUpdate", function()
  local elapsed = arg1
  if pendingRequest then
    requestDelay = requestDelay - elapsed
    if requestDelay <= 0 then
      pendingRequest = false
      SendAddonMessage(LB_PREFIX, LB_GET_DATA, GetNumRaidMembers() > 0 and "RAID" or "PARTY")
    end
  end
  if pendingSet then
    setDelay = setDelay - elapsed
    if setDelay <= 0 then
      pendingSet = false
      setDelay = 0.5

      if not state.masterLooter or (state.masterLooter ~= setName) then
        lb_print("Masterlooter set to |cFF00FF00" .. setName .. "|r")
      end
      state.masterLooter = setName
    end
  end
end)

function itemRollFrame:CHAT_MSG_LOOT(message)
  if not ItemRollFrame:IsVisible() or state.masterLooter ~= UnitName("player") then return end

  local _, _, who = string.find(message, "^(%a+) receive.? loot:")
  local links = ExtractItemLinksFromMessage(message)

  if who and tsize(links) == 1 then
    if this.itemLink == links[1] then
      resetRolls()
      this:Hide()
    end
  end
end

function itemRollFrame:CHAT_MSG_SYSTEM(message)
  local _, _, newML = string.find(message, "(.+) is now the loot master")
  if newML then
    itemRollFrame:SendML(newML)
    return
  end
end

function itemRollFrame:CHAT_MSG_RAID_WARNING(message, sender)
  if sender ~= state.masterLooter then return end

  local links = ExtractItemLinksFromMessage(message)
  if tsize(links) == 1 then
    if string.find(message, "^No one has nee") or
      string.find(message, "has been sent to") or
      string.find(message, " received ") or
      IsAwardAnnouncement(message) then
      return
    end
    resetRolls()
    GuildRoster()  -- request fresh DKP data from server
    UpdateTextArea(itemRollFrame)
    state.time_elapsed = 0
    state.isRolling = true
    ShowFrame(itemRollFrame, FrameShownDuration, links[1])
  end
end

function itemRollFrame:GUILD_ROSTER_UPDATE()
  -- Refresh DKP display if the frame is visible
  if ItemRollFrame:IsVisible() then
    UpdateTextArea(itemRollFrame)
  end
end

function itemRollFrame:SendML(masterlooter)
  if not masterlooter then return end

  local chan = GetNumRaidMembers() > 0 and "RAID" or "PARTY"
  SendAddonMessage(LB_PREFIX, LB_SET_ML .. masterlooter, chan)
end

function itemRollFrame:CHAT_MSG_ADDON(prefix, message, channel, sender)
  if prefix ~= LB_PREFIX then return end

  if message == LB_GET_DATA then
    self:SendML(GetMasterLooterInParty())
  end

  if string.find(message, LB_SET_ML) then
    if GetLootMethod() ~= "master" then return end
    local _, _, newML = string.find(message, "ML set to (%S+)")
    if newML then
      pendingSet = true
      setName = newML
    end
    return
  end

end

function itemRollFrame:RAID_ROSTER_UPDATE()
  RequestML(0.5)
end

function itemRollFrame:PARTY_MEMBERS_CHANGED()
  RequestML(0.5)
end

function itemRollFrame:PLAYER_ENTERING_WORLD()
  RequestML(8)
end

function itemRollFrame:PARTY_LOOT_METHOD_CHANGED()
  RequestML(0.5)
end

function itemRollFrame:ADDON_LOADED(addon)
  if addon ~= "BRPBidHelper" then return end

  if FrameShownDuration == nil then FrameShownDuration = 30 end
  if FrameAutoClose == nil then FrameAutoClose = true end
end

itemRollFrame:RegisterEvent("ADDON_LOADED")
itemRollFrame:RegisterEvent("CHAT_MSG_SYSTEM")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
itemRollFrame:RegisterEvent("CHAT_MSG_ADDON")
itemRollFrame:RegisterEvent("CHAT_MSG_LOOT")
itemRollFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
itemRollFrame:RegisterEvent("RAID_ROSTER_UPDATE")
itemRollFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
itemRollFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
itemRollFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

itemRollFrame:SetScript("OnEvent", function()
  itemRollFrame[event](itemRollFrame, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end)
