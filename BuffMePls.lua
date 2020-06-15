local _, L = ...;
local fontName, fontHeight, fontFlags = GameFontNormal:GetFont();
local CHAT_TYPE_WHISPER = "WHISPER"
local CHAT_TYPE_SAY = "SAY"
local DEFAULT_CHAT_TYPE = CHAT_TYPE_WHISPER

BTN_WIDTH = 22
BTN_HEIGHT = 22

-- unit class
UNIT_CLASS_PALAIN = 2
UNIT_CLASS_PRIEST = 5
UNIT_CLASS_MAGE = 8
UNIT_CLASS_DRUID = 11

-- [unitClassId] = {
--     [partyBuffspellID] = 'unitBuffspellID'
-- }
local BUFFS_ = {
    [UNIT_CLASS_PALAIN] = {
        ['25916'] = '19838',
        ['25898'] = '20217',
        ['25918'] = '25290',
        ['25895'] = '1038',
        ['25890'] = '19979'
    },

    [UNIT_CLASS_PRIEST] = {
        ['27681'] = '27841',
        ['21564'] = '10938',
        ['10958'] = '10958'
    },
    [UNIT_CLASS_MAGE] = {
        ['23028'] = '10157',
        ['10173'] = '10173',
        ['10170'] = '10170'
    },
    [UNIT_CLASS_DRUID] = {['21850'] = '9885', ['467'] = '467'}
}
local SHORT_BUFF_NAME = {
    ['27841'] = L['divine-spirit'],
    ['10938'] = L['power-word-fortitude'],
    ['10157'] = L['arcane-intellect'],
    ['9885'] = L['mark-of-the-wild'],
    ['19838'] = L['blessing-of-might'],
    ['20217'] = L['blessing-of-kings'],
    ['25290'] = L['blessing-of-wisdom'],
    ['1038'] = L['blessing-of-salvation'],
    ['19979'] = L['blessing-of-light'],
    ['10958'] = L['blessing-of-light'],
    ['467'] = L['blessing-of-light'],
    ['10173'] = L['blessing-of-light'],
    ['10170'] = L['blessing-of-light'],
}

function getRaidGroupNum()
    if UnitInRaid('player') then
        for i = 1, GetNumGroupMembers() do
            name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML =
                GetRaidRosterInfo(i)
            if (name == UnitName('player')) then return subgroup end
        end
    end

    return nil
end
function allBuffsTargetCouldCast(targetUnitClassId)
    local buffs = {}
    local spellIDs = {}
    for partyBuffspellID, unitBuffspellID in pairs(BUFFS_[targetUnitClassId]) do
        buffs[#buffs + 1] = GetSpellLink(unitBuffspellID);
        spellIDs[#spellIDs + 1] = unitBuffspellID;
    end
    if #buffs > 0 then return true, table.concat(buffs, ", "), spellIDs end

    return false, '', spellIDs
end

function getBuffsPlayerNeed(targetUnitClassId)
    local buffs = {}
    local spellIDs = {}
    for partyBuffspellID, unitBuffspellID in pairs(BUFFS_[targetUnitClassId]) do
        if not isPlayerNeedsBuff(GetSpellLink(partyBuffspellID)) and
            not isPlayerNeedsBuff(GetSpellLink(unitBuffspellID)) then
            buffs[#buffs + 1] = GetSpellLink(unitBuffspellID);
            spellIDs[#spellIDs + 1] = unitBuffspellID;
        end
    end
    if #buffs > 0 then return true, table.concat(buffs, ", "), spellIDs end

    return false, '', spellIDs
end

function isPlayerNeedsBuff(partySpellName)
    for index, buff in ipairs(CURRENT_BUFFS) do
        if buff == partySpellName then return true end
    end
    return false
end

function sendMessage(buffs, targetName)
    -- languanges
    local messages = ''

    local groupNum = getRaidGroupNum()
    if groupNum ~= nil then
        messages = string.format(L["i_am_in_group"], groupNum)
    end
    messages = messages .. string.format(L["would_you_buff_me_plz"], buffs)

    -- chat type

    if DEFAULT_CHAT_TYPE == CHAT_TYPE_WHISPER then -- whisper
        SendChatMessage(messages, CHAT_TYPE_WHISPER, nil, targetName)
    elseif DEFAULT_CHAT_TYPE == CHAT_TYPE_SAY then
        SendChatMessage(messages, chatType)
    end
end

function hideAllBuffButtons()
    for key, btn in pairs(BUFF_BUTTONS) do btn:Hide() end
end

function showBuffButtons(spellIDs)
    for i, id in ipairs(spellIDs) do
        local btn = BUFF_BUTTONS[id]
        btn:Show()
        btn:SetPoint('RIGHT', BTN_WIDTH * i, 0)
    end
end

BUFF_BUTTONS = {}
function createBuffButtons()
    local i = 1;
    for spellID, name in pairs(SHORT_BUFF_NAME) do
        local btn = CreateFrame("Button", nil, BuffMePls_Button,
                                "UIPanelButtonTemplate")
        btn:SetSize(BTN_WIDTH, BTN_HEIGHT) -- width, height
        -- btn:SetText(name)
        btn:SetPoint('RIGHT', BTN_WIDTH * i, 0)

        local texture = GetSpellTexture(spellID)
        btn:SetNormalTexture(texture)

        btn:SetScript("OnClick", function()
            local buffs = GetSpellLink(spellID)
            local targetName = UnitName('target')
            sendMessage(buffs, targetName)
        end)
        btn:SetScript("OnEnter", function(self, motion)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("BuffMePls")
            GameTooltip:AddLine(string.format(L['ask_for_unit_buff'],
                                              GetSpellLink(spellID)))
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self, motion)
            GameTooltip:Hide()
        end)

        i = i + 1
        BUFF_BUTTONS[spellID] = btn
    end
end

function BuffMePls_Frame_Mouse_Event(self, button)
    local targetUnitClassId = select(3, UnitClass('target'))
    local targetName = UnitName('target')

    local isNeed, buffs = allBuffsTargetCouldCast(targetUnitClassId)
    if isNeed and targetName then sendMessage(buffs, targetName) end
end

BuffMePls_Button = CreateFrame("Button", "BuffMePlsButton", UIParent,
                               "UIPanelButtonTemplate")
BuffMePls_Button:SetSize(BTN_WIDTH, BTN_HEIGHT) -- width, height
BuffMePls_Button:SetText(L["BuffMePls"])
-- BuffMePls_Button:SetPoint('RIGHT', TargetFrame, 'TOPRIGHT', 0, 0)
BuffMePls_Button:SetPoint('CENTER')
BuffMePls_Button:SetScript("OnClick", BuffMePls_Frame_Mouse_Event)
BuffMePls_Button:Hide()

BuffMePls_Button:SetMovable(true)
BuffMePls_Button:EnableMouse(true)
BuffMePls_Button:RegisterForDrag("RightButton")
BuffMePls_Button:SetScript("OnDragStart", BuffMePls_Button.StartMoving)
BuffMePls_Button:SetScript("OnDragStop", BuffMePls_Button.StopMovingOrSizing)

BuffMePls_Button:SetScript("OnEnter", function(self, motion)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("BuffMePls")
    GameTooltip:AddLine(L['ask_for_all_buffs'])
    GameTooltip:AddLine(L["moveable"])
    GameTooltip:Show()
end)
BuffMePls_Button:SetScript("OnLeave",
                           function(self, motion) GameTooltip:Hide() end)

createBuffButtons()

function Player_Target_Changed_Event(self, event, ...)
    local targetUnitClassId = select(3, UnitClass('target'))
    if UnitIsPlayer('target') and UnitIsFriend("player", "target") and
        BUFFS_[targetUnitClassId] then
        hideAllBuffButtons()
        local _, _, spellIDs = getBuffsPlayerNeed(targetUnitClassId)
        showBuffButtons(spellIDs)
        BuffMePls_Button:Show()
    else
        BuffMePls_Button:Hide()
    end
end

CURRENT_BUFFS = {};
function updatePlayerBuffs(self, event, ...)
    CURRENT_BUFFS = {};
    local i = 1;
    local spellName, iconTexture, count, debuffType, duration, expirationTime,
          source, _, _, spellID = UnitBuff("player", i);

    while spellName do
        CURRENT_BUFFS[#CURRENT_BUFFS + 1] = spellName;
        i = i + 1;
        spellName = UnitBuff("player", i);

    end
    -- DEFAULT_CHAT_FRAME:AddMessage(table.concat(CURRENT_BUFFS, ", "));
end

function BuffMePlsFrame_Event(self, event)
    if event == 'UNIT_AURA' or event == 'PLAYER_ENTERING_WORLD' then
        updatePlayerBuffs(self, event)
    elseif event == 'PLAYER_TARGET_CHANGED' then
        Player_Target_Changed_Event(self, event)
    end
end

local BuffMePlsFrame = CreateFrame('Frame')
BuffMePlsFrame:RegisterEvent('UNIT_AURA')
BuffMePlsFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
BuffMePlsFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
BuffMePlsFrame:SetScript('OnEvent', BuffMePlsFrame_Event)
