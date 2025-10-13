-- PapaGreet.lua

-- API Abstraction Layer (future-proof for Midnight)
local PapaGreetAPI = {}

-- Safe error handler wrapper
local function SafeCall(func, ...)
    local success, result = xpcall(func, geterrorhandler(), ...)
    if not success then
        print("|cffff0000PapaGreet Error:|r " .. tostring(result))
    end
    return success, result
end

-- Initialize API layer with version detection
function PapaGreetAPI:Initialize()
    local apiVersion = select(4, GetBuildInfo())
    self.isMidnight = apiVersion >= 120000
    self.isModern = apiVersion >= 100000
    
    -- Chat API
    self.SendChatMessage = function(msg, channel)
        SafeCall(SendChatMessage, msg, channel)
    end
    
    -- Emote API (ready for C_Emote in Midnight)
    if C_Emote and C_Emote.DoEmote then
        self.DoEmote = function(emote)
            SafeCall(C_Emote.DoEmote, emote)
        end
    else
        self.DoEmote = function(emote)
            SafeCall(DoEmote, emote)
        end
    end
    
    -- Party API
    if C_PartyInfo and C_PartyInfo.LeaveParty then
        self.LeaveParty = function()
            SafeCall(C_PartyInfo.LeaveParty)
        end
    else
        self.LeaveParty = function()
            SafeCall(LeaveGroup)
        end
    end
end

PapaGreetAPI:Initialize()

-- Localize globals for performance
local CreateFrame = CreateFrame
local UIParent = UIParent
local math_random = math.random
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local InCombatLockdown = InCombatLockdown
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
                    cooldown = 3,
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
    -- Ensure all profiles have cooldown field
    for _, profile in pairs(PapaGreetSavedVariables.profiles) do
        if profile.cooldown == nil then
            profile.cooldown = 3
        end
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

-- Combat-safe greeting queue system
local greetingQueue = {}

local function ProcessGreetingQueue()
    if #greetingQueue > 0 then
        for i, queuedGreeting in ipairs(greetingQueue) do
            PapaGreetAPI.SendChatMessage(queuedGreeting.message, queuedGreeting.channel)
            if queuedGreeting.emote then
                C_Timer.After(queuedGreeting.delayEmote, function()
                    PapaGreetAPI.DoEmote(queuedGreeting.emote)
                end)
            end
        end
        wipe(greetingQueue)
        UIErrorsFrame:AddMessage("Queued greetings sent!", 0.0, 1.0, 0.0)
    end
end

-- Modern event system support (EventRegistry for retail 10+, fallback for older clients)
if EventRegistry then
    -- Use modern EventRegistry API
    EventRegistry:RegisterCallback("PLAYER_REGEN_ENABLED", ProcessGreetingQueue)
else
    -- Fallback to traditional event system
    local combatEventFrame = CreateFrame("Frame")
    combatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatEventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_ENABLED" then
            ProcessGreetingQueue()
        end
    end)
end

local function SendMessageAndEmote(message, emote, delayEmote)
    local channel = DetermineChatChannel()
    
    -- Check if in combat
    if InCombatLockdown() then
        table.insert(greetingQueue, {
            message = message,
            channel = channel,
            emote = emote,
            delayEmote = delayEmote or 3
        })
        UIErrorsFrame:AddMessage("Greeting queued (in combat)", 1.0, 1.0, 0.0)
        return
    end
    
    -- Send immediately if not in combat
    if message then
        PapaGreetAPI.SendChatMessage(message, channel)
    end
    if emote then
        C_Timer.After(delayEmote, function()
            PapaGreetAPI.DoEmote(emote)
        end)
    end
end

local leaveTimer
local leaveTimerActive = false
local leaveCountdownTicker
local leaveTimeRemaining = 0
local papaGreetButton -- Forward declaration

-- Cooldown system
local lastGreetingTime = 0
local lastGoodbyeTime = 0

local function IsOnCooldown(lastTime, cooldown)
    return (GetTime() - lastTime) < cooldown
end

local function GetCooldownRemaining(lastTime, cooldown)
    local remaining = cooldown - (GetTime() - lastTime)
    return remaining > 0 and remaining or 0
end

local function UpdateCooldownDisplay()
    if not papaGreetButton or not papaGreetButton.cooldown then return end
    
    local profile = GetProfile()
    local cooldown = profile.cooldown or 0
    
    if cooldown == 0 then
        papaGreetButton.cooldown:Hide()
        return
    end
    
    -- Check both greeting and goodbye cooldowns
    local greetCd = GetCooldownRemaining(lastGreetingTime, cooldown)
    local goodbyeCd = GetCooldownRemaining(lastGoodbyeTime, cooldown)
    local maxCd = math.max(greetCd, goodbyeCd)
    
    if maxCd > 0 then
        papaGreetButton.cooldown:SetCooldown(GetTime() - (cooldown - maxCd), cooldown)
        papaGreetButton.cooldown:Show()
    else
        papaGreetButton.cooldown:Hide()
    end
end

local function HandleGreeting()
    local profile = GetProfile()
    
    -- Check cooldown
    local cooldown = profile.cooldown or 0
    if cooldown > 0 and IsOnCooldown(lastGreetingTime, cooldown) then
        local remaining = GetCooldownRemaining(lastGreetingTime, cooldown)
        UIErrorsFrame:AddMessage(string.format("Greeting on cooldown (%.1fs remaining)", remaining), 1.0, 0.5, 0.0)
        -- Shake animation
        if papaGreetButton then
            papaGreetButton:SetPoint(papaGreetButton:GetPoint())
            papaGreetButton:StartMoving()
            papaGreetButton:StopMovingOrSizing()
        end
        return
    end
    
    if not profile.greetings or #profile.greetings == 0 then
        UIErrorsFrame:AddMessage("No greetings configured. Use /papa menu to add some.", 1.0, 0.0, 0.0)
        return
    end
    
    local greeting = profile.greetings[math_random(#profile.greetings)]
    local emote = (#profile.greetingEmotes > 0) and profile.greetingEmotes[math_random(#profile.greetingEmotes)] or nil
    SendMessageAndEmote(greeting, emote, profile.delayEmote)
    
    -- Set cooldown
    lastGreetingTime = GetTime()
    UpdateCooldownDisplay()
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
    
    -- Check cooldown
    local cooldown = profile.cooldown or 0
    if cooldown > 0 and IsOnCooldown(lastGoodbyeTime, cooldown) then
        local remaining = GetCooldownRemaining(lastGoodbyeTime, cooldown)
        UIErrorsFrame:AddMessage(string.format("Goodbye on cooldown (%.1fs remaining)", remaining), 1.0, 0.5, 0.0)
        -- Shake animation
        if papaGreetButton then
            papaGreetButton:SetPoint(papaGreetButton:GetPoint())
            papaGreetButton:StartMoving()
            papaGreetButton:StopMovingOrSizing()
        end
        return
    end
    
    if not profile.goodbyes or #profile.goodbyes == 0 then
        UIErrorsFrame:AddMessage("No goodbyes configured. Use /papa menu to add some.", 1.0, 0.0, 0.0)
        return
    end
    
    local goodbye = profile.goodbyes[math_random(#profile.goodbyes)]
    local emote = (#profile.goodbyeEmotes > 0) and profile.goodbyeEmotes[math_random(#profile.goodbyeEmotes)] or nil
    SendMessageAndEmote(goodbye, emote, profile.delayEmote)
    
    -- Set cooldown
    lastGoodbyeTime = GetTime()
    UpdateCooldownDisplay()
    
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
    leaveTimer = C_Timer.NewTimer(profile.delayLeave, function()
        if leaveTimerActive then
            if IsInGroup() then
                PapaGreetAPI.LeaveParty()
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

    -- Create cooldown frame overlay
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button)
    button.cooldown:SetDrawEdge(true)
    button.cooldown:SetDrawSwipe(true)
    button.cooldown:SetReverse(false)
    button.cooldown:Hide()

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
    local command, arg = cmd:match("^(%S*)%s*(.-)$")
    
    if not command or command == "" then
        print("|cff00ff00PapaGreet Commands:|r")
        print("  |cffffd700/papa greet|r - Send greeting")
        print("  |cffffd700/papa bye|r - Send goodbye & leave")
        print("  |cffffd700/papa cancel|r - Cancel leave timer")
        print("  |cffffd700/papa menu|r - Toggle settings menu")
        print("  |cffffd700/papa hide|r - Hide button")
        print("  |cffffd700/papa show|r - Show button")
        print("  |cffffd700/papa reset|r - Reset button position")
        print("  |cffffd700/papa cd [seconds]|r - Set cooldown (0=off)")
        print("  |cffffd700/papa version|r - Show version")
        return
    end

    if command == "greet" then
        HandleGreeting()
    elseif command == "bye" or command == "goodbye" then
        HandleGoodbye()
    elseif command == "cancel" then
        CancelLeave()
    elseif command == "menu" then
        TogglePapaGreetMenu()
    elseif command == "hide" then
        papaGreetButton:Hide()
        print("PapaGreet button hidden. Use |cffffd700/papa show|r to show it.")
    elseif command == "show" then
        papaGreetButton:Show()
        print("PapaGreet button shown.")
    elseif command == "reset" then
        PapaGreetSavedVariables.buttonPosition = { point = "CENTER", x = 0, y = 0 }
        papaGreetButton:ClearAllPoints()
        papaGreetButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        print("PapaGreet button position reset to center.")
    elseif command == "cd" or command == "cooldown" then
        local value = tonumber(arg)
        if value and value >= 0 then
            local profile = GetProfile()
            profile.cooldown = math.floor(value)
            if value == 0 then
                print("Cooldown disabled.")
            else
                print(string.format("Cooldown set to %d seconds.", value))
            end
        else
            print("Usage: /papa cd [seconds] (0 to disable)")
        end
    elseif command == "version" or command == "v" then
        print("|cff00ff00PapaGreet|r version |cffffd7001.2.0|r")
    else
        print("|cffff0000Unknown command:|r " .. command)
        print("Type |cffffd700/papa|r for help.")
    end
end
