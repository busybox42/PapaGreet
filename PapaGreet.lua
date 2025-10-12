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
            currentProfile = DEFAULT_PROFILE,
            buttonPosition = { point = "CENTER", x = 0, y = 0 }
        }
    end
    -- Ensure buttonPosition exists for existing saves
    if not PapaGreetSavedVariables.buttonPosition then
        PapaGreetSavedVariables.buttonPosition = { point = "CENTER", x = 0, y = 0 }
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
        pcall(SendChatMessage, message, DetermineChatChannel())
    end
    if emote then
        C_Timer_NewTimer(delayEmote, function() pcall(DoEmote, emote) end)
    end
end

local leaveTimer
local leaveTimerActive = false
local leaveCountdownTicker
local leaveTimeRemaining = 0
local papaGreetButton -- Forward declaration

local function HandleGreeting()
    local profile = GetProfile()
    if not profile.greetings or #profile.greetings == 0 then
        UIErrorsFrame:AddMessage("No greetings configured. Use /papa menu to add some.", 1.0, 0.0, 0.0)
        return
    end
    local greeting = profile.greetings[math_random(#profile.greetings)]
    local emote = (#profile.greetingEmotes > 0) and profile.greetingEmotes[math_random(#profile.greetingEmotes)] or nil
    SendMessageAndEmote(greeting, emote, profile.delayEmote)
end

local function UpdateLeaveCountdown()
    if not papaGreetButton or not papaGreetButton.countdownText then return end
    
    if leaveTimeRemaining > 0 then
        papaGreetButton.countdownText:SetText(leaveTimeRemaining)
        papaGreetButton.countdownText:Show()
        -- Pulse animation
        local scale = 1.0 + (0.2 * math.sin(GetTime() * 5))
        papaGreetButton.countdownText:SetScale(scale)
    else
        papaGreetButton.countdownText:Hide()
    end
end

local function StopLeaveCountdown()
    if leaveCountdownTicker then
        leaveCountdownTicker:Cancel()
        leaveCountdownTicker = nil
    end
    leaveTimeRemaining = 0
    if papaGreetButton and papaGreetButton.countdownText then
        papaGreetButton.countdownText:Hide()
    end
end

local function HandleGoodbye()
    local profile = GetProfile()
    if not profile.goodbyes or #profile.goodbyes == 0 then
        UIErrorsFrame:AddMessage("No goodbyes configured. Use /papa menu to add some.", 1.0, 0.0, 0.0)
        return
    end
    local goodbye = profile.goodbyes[math_random(#profile.goodbyes)]
    local emote = (#profile.goodbyeEmotes > 0) and profile.goodbyeEmotes[math_random(#profile.goodbyeEmotes)] or nil
    SendMessageAndEmote(goodbye, emote, profile.delayEmote)
    
    -- Start the leave timer with visual countdown
    leaveTimerActive = true
    leaveTimeRemaining = profile.delayLeave
    
    -- Update countdown every second
    leaveCountdownTicker = C_Timer.NewTicker(1, function()
        leaveTimeRemaining = leaveTimeRemaining - 1
        UpdateLeaveCountdown()
        
        if leaveTimeRemaining <= 0 then
            StopLeaveCountdown()
        end
    end, profile.delayLeave)
    
    -- Initial display
    UpdateLeaveCountdown()
    
    -- Final action timer
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
            StopLeaveCountdown()
        end
    end)
end

local function CancelLeave()
    if leaveTimerActive and leaveTimer then
        leaveTimerActive = false
        leaveTimer:Cancel()
        leaveTimer = nil
        StopLeaveCountdown()
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

    -- Restore saved position
    local pos = PapaGreetSavedVariables.buttonPosition
    button:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    button:SetClampedToScreen(true)
    button:SetMovable(true)
    button:SetFrameStrata(BUTTON_STRATA)
    button:SetAlpha(BUTTON_ALPHA)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:Show()

    -- Add tooltips
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("PapaGreet", 1, 1, 1)
        GameTooltip:AddLine("Left Click: Greet", 0.5, 1, 0.5)
        GameTooltip:AddLine("Right Click: Goodbye & Leave", 1, 0.5, 0.5)
        GameTooltip:AddLine("Ctrl+Left: Settings", 0.5, 0.5, 1)
        GameTooltip:AddLine("Ctrl+Right: Cancel Leave", 1, 1, 0)
        GameTooltip:AddLine("Shift+Left: LFD", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift+Right: PVP", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Middle Drag: Move", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Create countdown text overlay
    button.countdownText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    button.countdownText:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.countdownText:SetTextColor(1, 0, 0, 1)
    button.countdownText:Hide()

    button:SetScript("OnMouseDown", function(self, button)
        if button == "MiddleButton" then
            self:StartMoving()
        end
    end)

    button:SetScript("OnMouseUp", function(self, button)
        if button == "MiddleButton" then
            self:StopMovingOrSizing()
            -- Save position
            local point, _, _, x, y = self:GetPoint()
            PapaGreetSavedVariables.buttonPosition = { point = point, x = x, y = y }
            return
        end
        OnButtonClick(self, button)
    end)

    return button
end

papaGreetButton = CreatePapaGreetButton()

-- Keybindings
BINDING_HEADER_PAPAGREET = "PapaGreet"
BINDING_NAME_PAPAGREET_GREET = "Send Greeting"
BINDING_NAME_PAPAGREET_GOODBYE = "Send Goodbye & Leave"
BINDING_NAME_PAPAGREET_CANCEL = "Cancel Leave"
BINDING_NAME_PAPAGREET_MENU = "Toggle Menu"

function PapaGreet_SendGreeting()
    HandleGreeting()
end

function PapaGreet_SendGoodbye()
    HandleGoodbye()
end

function PapaGreet_CancelLeave()
    CancelLeave()
end

function PapaGreet_ToggleMenu()
    TogglePapaGreetMenu()
end

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
