-- PapaGreet.lua

local CreateFrame = CreateFrame
local UIParent = UIParent
local math_random = math.random
local SendChatMessage = SendChatMessage
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local DoEmote = DoEmote
local C_Timer_NewTimer = C_Timer.NewTimer
local C_PartyInfo_LeaveParty = C_PartyInfo.LeaveParty
local GetInstanceInfo = GetInstanceInfo
local ToggleLFDParentFrame = ToggleLFDParentFrame
local TogglePVPUI = TogglePVPUI
local PVEFrame_ToggleFrame = PVEFrame_ToggleFrame
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local print = print

-- Constants
local DEFAULT_PROFILE = "Default"
local SPELL_ID = 226582
local BUTTON_SIZE = 40
local BUTTON_STRATA = "HIGH"
local BUTTON_ALPHA = 1
local SLASH_COMMAND = '/papa'

-- Initialize saved variables
local function Initialize()
    if not PapaGreetSavedVariables then
        PapaGreetSavedVariables = {
            profiles = {
                [DEFAULT_PROFILE] = {
                    greetings = {
                        "Hail, champions!",
                        "Greetings, heroes!",
                        "Greetings!",
                        "Salutations, adventurers!",
                        "Well met!",
                        "Good evening!"
                    },
                    goodbyes = {
                        "Farewell, champions. May your blade be sharp and your armor strong.",
                        "Until we meet again, heroes.",
                        "Safe travels, adventurers.",
                        "Until next time champions!"
                    },
                    greetingEmotes = {
                        "wave", "crack", "cheer", "charge", "brandish",
                        "bow", "hi", "hail", "nod", "grin"
                    },
                    goodbyeEmotes = {
                        "drink", "wave", "cheer", "dance", "hug",
                        "bow", "bye", "nod", "victory", "yay"
                    },
                    delayEmote = 3,
                    delayLeave = 8,
                }
            },
            currentProfile = DEFAULT_PROFILE
        }
    end
    return PapaGreetSavedVariables.currentProfile
end

local currentProfile = Initialize()

-- Helper functions
local function GetProfile()
    return PapaGreetSavedVariables.profiles[currentProfile]
end

local function DetermineChatChannel()
    if IsInGroup() then
        return IsInInstance() and "INSTANCE_CHAT" or "PARTY"
    else
        return "SAY"
    end
end

local function SendMessageAndEmote(message, emote, delayEmote)
    if message then
        SendChatMessage(message, DetermineChatChannel())
    end
    if emote then
        C_Timer_NewTimer(delayEmote, function() DoEmote(emote) end)
    else
        DoEmote(emote)
    end
end

local leaveTimer
local leaveTimerActive = false

local function HandleGreeting()
    local profile = GetProfile()
    -- Proceed with greeting message and emote
    local greeting = profile.greetings[math_random(#profile.greetings)]
    local emote = profile.greetingEmotes[math_random(#profile.greetingEmotes)]
    SendMessageAndEmote(greeting, emote, profile.delayEmote)
end

local function HandleGoodbye()
    local profile = GetProfile()
    local goodbye = profile.goodbyes[math_random(#profile.goodbyes)]
    local emote = profile.goodbyeEmotes[math_random(#profile.goodbyeEmotes)]
    SendMessageAndEmote(goodbye, emote, profile.delayEmote)
    
    -- Start the leave timer
    leaveTimerActive = true
    leaveTimer = C_Timer_NewTimer(profile.delayLeave, function()
                if leaveTimerActive then
            if IsInGroup() then
                C_PartyInfo_LeaveParty()
                UIErrorsFrame:AddMessage("You have left the group.", 1.0, 1.0, 0.0)
            else
                UIErrorsFrame:AddMessage("You are not in a group.", 1.0, 1.0, 0.0)
            end
            leaveTimerActive = false
            leaveTimer = nil
        end
    end)
    end

local function CancelLeave()
        if leaveTimerActive and leaveTimer then
        leaveTimerActive = false
        leaveTimer:Cancel()
        leaveTimer = nil
                UIErrorsFrame:AddMessage("Leave group action has been canceled.", 1.0, 1.0, 0.0)
    else
                UIErrorsFrame:AddMessage("No active leave action to cancel.", 1.0, 1.0, 0.0)
    end
end

local function OnButtonClick(self, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            ToggleLFDParentFrame()
        elseif IsControlKeyDown() then
            TogglePapaGreetMenu()
        else
            HandleGreeting()
        end
    elseif button == "RightButton" then
        if IsShiftKeyDown() then
            TogglePVPUI()
        elseif IsControlKeyDown() then
            -- Cancel leave if Control + Right Click
            CancelLeave()
        else
            HandleGoodbye()
        end
    end
end

-- Create the main button
local function CreatePapaGreetButton()
    local button = CreateFrame("Button", "PapaGreetButton", UIParent, "UIPanelButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    local spellTexture = C_Spell.GetSpellTexture(SPELL_ID)
    local texture = spellTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
    button:SetNormalTexture(texture)
    button:SetPushedTexture(texture)
    button:SetDisabledTexture(texture)

    button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    button:SetClampedToScreen(false)
    button:SetMovable(true)
    button:SetFrameStrata(BUTTON_STRATA)
    button:SetAlpha(BUTTON_ALPHA)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:Show()

    button:SetScript("OnMouseDown", function(self, button)
        if button == "MiddleButton" then
            self:StartMoving()
        end
    end)

    button:SetScript("OnMouseUp", function(self, button)
        if button == "MiddleButton" then
            self:StopMovingOrSizing()
            return
        end
        OnButtonClick(self, button)
    end)

    return button
end

local papaGreetButton = CreatePapaGreetButton()

-- Slash command handling
SLASH_PAPA1 = SLASH_PAPA1 or '/papa'

SlashCmdList["PAPA"] = function(cmd)
    local command = cmd:match("^%S+")
    if not command then
        print("Usage: /papa menu | hide | show")
        return
    end

    if command == "menu" then
        TogglePapaGreetMenu()
    elseif command == "hide" then
        papaGreetButton:Hide()
    elseif command == "show" then
        papaGreetButton:Show()
    else
        print("Usage: /papa menu | hide | show")
    end
end
