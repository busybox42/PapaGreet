-- PapaGreetMenu.lua

-- Localize globals for performance
local CreateFrame = CreateFrame
local UIParent = UIParent
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local UIDropDownMenu_SetSelectedValue = UIDropDownMenu_SetSelectedValue
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
local print = print
local table_insert = table.insert
local table_remove = table.remove
local math_floor = math.floor
local tonumber = tonumber

-- Constants
local DEFAULT_PROFILE = "Default"

-- Deep copy utility
local function deepcopy(orig)
    if type(orig) ~= 'table' then return orig end
    local copy = {}
    for k, v in next, orig, nil do
        copy[deepcopy(k)] = deepcopy(v)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
    return copy
end

-- Initialize saved variables and current profile
local function InitializeVariables()
    PapaGreetSavedVariables = PapaGreetSavedVariables or {}
    PapaGreetSavedVariables.profiles = PapaGreetSavedVariables.profiles or {}
    PapaGreetSavedVariables.profiles[DEFAULT_PROFILE] = PapaGreetSavedVariables.profiles[DEFAULT_PROFILE] or {
        greetings = {},
        goodbyes = {},
        greetingEmotes = {},
        goodbyeEmotes = {},
        delayEmote = 3,
        delayLeave = 8,
        castBuff = false,
        buffSpell = nil,
    }
    PapaGreetSavedVariables.currentProfile = PapaGreetSavedVariables.currentProfile or DEFAULT_PROFILE
    
    -- Ensure all profiles have necessary fields
    for name, profile in pairs(PapaGreetSavedVariables.profiles) do
        profile.greetings = profile.greetings or {}
        profile.goodbyes = profile.goodbyes or {}
        profile.greetingEmotes = profile.greetingEmotes or {}
        profile.goodbyeEmotes = profile.goodbyeEmotes or {}
        profile.castBuff = profile.castBuff ~= nil and profile.castBuff or false
        profile.buffSpell = profile.buffSpell or nil
        profile.delayEmote = profile.delayEmote or 3
        profile.delayLeave = profile.delayLeave or 8
    end
end

InitializeVariables()
local currentProfile = PapaGreetSavedVariables.currentProfile

-- Function to update the buff spell display
local function UpdateBuffSpellText()
    local buffSpell = PapaGreetSavedVariables.profiles[currentProfile].buffSpell
    local buffSpellText = _G["PapaGreetBuffSpellText"]
    if buffSpellText then
        if buffSpell and buffSpell ~= "" then
            buffSpellText:SetText("Current Buff Spell: " .. buffSpell)
        else
            buffSpellText:SetText("No Buff Spell Set")
        end
    end
end

-- Refresh the menu UI
local function RefreshPapaGreetMenu()
    currentProfile = PapaGreetSavedVariables.currentProfile
    local emoteDelayEditBox = _G["PapaGreetDelayEditBox"]
    if emoteDelayEditBox then
        emoteDelayEditBox:SetText(math_floor(PapaGreetSavedVariables.profiles[currentProfile].delayEmote or 3))
    end
    
    local leaveDelayEditBox = _G["PapaGreetLeaveDelayEditBox"]
    if leaveDelayEditBox then
        leaveDelayEditBox:SetText(math_floor(PapaGreetSavedVariables.profiles[currentProfile].delayLeave or 8))
    end
    
    UIDropDownMenu_SetSelectedValue(PapaGreetProfileDropdown, currentProfile)
    
    -- Update the checkbox state
    local castBuffCheckbox = _G["PapaGreetCastBuffCheckbox"]
    if castBuffCheckbox then
        castBuffCheckbox:SetChecked(PapaGreetSavedVariables.profiles[currentProfile].castBuff or false)
    end

    -- Update the buff spell display text
    UpdateBuffSpellText()
end

-- Helper function to create buttons
local function createButton(name, parent, point, offsetX, offsetY, width, height, text, popup)
    local btn = CreateFrame("Button", name, parent, "GameMenuButtonTemplate")
    btn:SetPoint(point, offsetX, offsetY)
    btn:SetSize(width, height)
    btn:SetText(text)
    btn:SetScript("OnClick", function()
        if popup then StaticPopup_Show(popup) end
    end)
    return btn
end

-- Helper function to create dropdown menus for deleting items
local function createDeleteDropdown(name, parent, point, offsetX, offsetY, width, itemsKey)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint(point, offsetX, offsetY)
    dropdown:SetSize(width, 25)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local items = PapaGreetSavedVariables.profiles[currentProfile][itemsKey]
        for i, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item
            info.func = function()
                table_remove(items, i)
                RefreshPapaGreetMenu()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

-- Show the menu
function ShowPapaGreetMenu()
    local menu = CreateFrame("Frame", "PapaGreetMenu", UIParent, "BasicFrameTemplate")
    menu:SetSize(380, 420) -- Increased height to accommodate new elements
    menu:SetPoint("CENTER")
    menu:SetFrameStrata("DIALOG")
    menu:SetMovable(true)
    menu:EnableMouse(true)

    -- Title
    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", menu, "TOP", 0, -5)
    title:SetText("PapaGreet Menu")

    -- Enable moving the frame with MiddleButton
    menu:SetScript("OnMouseDown", function(self, button)
        if button == "MiddleButton" then self:StartMoving() end
    end)
    menu:SetScript("OnMouseUp", function(self, button)
        if button == "MiddleButton" then self:StopMovingOrSizing() end
    end)

    -- Profile Dropdown
    local profileDropdown = CreateFrame("Frame", "PapaGreetProfileDropdown", menu, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOPLEFT", menu, "TOPLEFT", 190, -30)

    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
        for name, _ in pairs(PapaGreetSavedVariables.profiles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.func = function()
                currentProfile = name
                PapaGreetSavedVariables.currentProfile = currentProfile
                UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
                RefreshPapaGreetMenu()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)

    -- Create Profile Buttons
    createButton("PapaGreetCreateProfileButton", menu, "TOPRIGHT", -240, -30, 120, 27, "Create Profile", "PAPA_GREET_CREATE_PROFILE")
    createButton("PapaGreetDeleteProfileButton", menu, "TOPRIGHT", -240, -70, 120, 27, "Delete Profile", "PAPA_GREET_DELETE_PROFILE")
    createButton("PapaGreetCopyProfileButton", menu, "TOPLEFT", 207, -70, 120, 27, "Copy Profile", "PAPA_GREET_COPY_PROFILE")

    -- Helper function to create delay labels and edit boxes
    local function createDelay(labelText, editBoxName, yOffset)
        local label = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", menu, "TOPLEFT", 20, yOffset)
        label:SetText(labelText)

        local editBox = CreateFrame("EditBox", editBoxName, menu, "InputBoxTemplate")
        editBox:SetSize(50, 25)
        editBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
        editBox:SetNumeric(true)
        editBox:SetMaxLetters(2)
        editBox:SetAutoFocus(false)
        local delayKey = editBoxName == "PapaGreetDelayEditBox" and "delayEmote" or "delayLeave"
        editBox:SetText(math_floor(PapaGreetSavedVariables.profiles[currentProfile][delayKey] or (delayKey == "delayEmote" and 3 or 8)))

        editBox:SetScript("OnEnterPressed", function(self)
            local inputValue = tonumber(self:GetText())
            if inputValue then
                PapaGreetSavedVariables.profiles[currentProfile][delayKey] = math_floor(inputValue)
                RefreshPapaGreetMenu()
            else
                print("Invalid input for " .. delayKey)
            end
            self:ClearFocus()
        end)
    end

    -- Create Delay EditBoxes
    createDelay("Emote Delay (seconds):", "PapaGreetDelayEditBox", -120)
    createDelay("Leave Delay (seconds):", "PapaGreetLeaveDelayEditBox", -160)

    -- Create Add Greeting Button and Delete Greeting Dropdown
    createButton("PapaGreetAddGreetingButton", menu, "TOPLEFT", 20, -200, 140, 27, "Add Greeting", "PAPA_GREET_ADD_GREETING")
    createDeleteDropdown("PapaGreetDeleteGreetingDropdown", menu, "TOPLEFT", 180, -200, 140, "greetings")

    -- Create Add Goodbye Button and Delete Goodbye Dropdown
    createButton("PapaGreetAddGoodbyeButton", menu, "TOPLEFT", 20, -240, 140, 27, "Add Goodbye", "PAPA_GREET_ADD_GOODBYE")
    createDeleteDropdown("PapaGreetDeleteGoodbyeDropdown", menu, "TOPLEFT", 180, -240, 140, "goodbyes")

    -- Create Add Greeting Emote Button and Delete Greeting Emote Dropdown
    createButton("PapaGreetAddGreetingEmoteButton", menu, "TOPLEFT", 20, -280, 140, 27, "Add Greeting Emote", "PAPA_GREET_ADD_GREETING_EMOTE")
    createDeleteDropdown("PapaGreetDeleteGreetingEmoteDropdown", menu, "TOPLEFT", 180, -280, 140, "greetingEmotes")

    -- Create Add Goodbye Emote Button and Delete Goodbye Emote Dropdown
    createButton("PapaGreetAddGoodbyeEmoteButton", menu, "TOPLEFT", 20, -320, 140, 27, "Add Goodbye Emote", "PAPA_GREET_ADD_GOODBYE_EMOTE")
    createDeleteDropdown("PapaGreetDeleteGoodbyeEmoteDropdown", menu, "TOPLEFT", 180, -320, 140, "goodbyeEmotes")

    -- Define Static Popups for Adding Greetings and Emotes
    StaticPopupDialogs["PAPA_GREET_ADD_GREETING"] = {
        text = "Enter the greeting message:",
        button1 = "Add",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText("")
        end,
        OnAccept = function(self)
            local greeting = self.editBox:GetText()
            if greeting and greeting ~= "" then
                table_insert(PapaGreetSavedVariables.profiles[currentProfile].greetings, greeting)
                RefreshPapaGreetMenu()
            else
                print("Greeting cannot be empty.")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 1)
        end,
        EditBoxOnEscapePressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 2)
        end
    }

    StaticPopupDialogs["PAPA_GREET_ADD_GOODBYE"] = {
        text = "Enter the goodbye message:",
        button1 = "Add",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText("")
        end,
        OnAccept = function(self)
            local goodbye = self.editBox:GetText()
            if goodbye and goodbye ~= "" then
                table_insert(PapaGreetSavedVariables.profiles[currentProfile].goodbyes, goodbye)
                RefreshPapaGreetMenu()
            else
                print("Goodbye cannot be empty.")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 1)
        end,
        EditBoxOnEscapePressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 2)
        end
    }

    StaticPopupDialogs["PAPA_GREET_ADD_GREETING_EMOTE"] = {
        text = "Enter the greeting emote:",
        button1 = "Add",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText("")
        end,
        OnAccept = function(self)
            local emote = self.editBox:GetText()
            if emote and emote ~= "" then
                table_insert(PapaGreetSavedVariables.profiles[currentProfile].greetingEmotes, emote)
                RefreshPapaGreetMenu()
            else
                print("Greeting emote cannot be empty.")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 1)
        end,
        EditBoxOnEscapePressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 2)
        end
    }

    StaticPopupDialogs["PAPA_GREET_ADD_GOODBYE_EMOTE"] = {
        text = "Enter the goodbye emote:",
        button1 = "Add",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText("")
        end,
        OnAccept = function(self)
            local emote = self.editBox:GetText()
            if emote and emote ~= "" then
                table_insert(PapaGreetSavedVariables.profiles[currentProfile].goodbyeEmotes, emote)
                RefreshPapaGreetMenu()
            else
                print("Goodbye emote cannot be empty.")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 1)
        end,
        EditBoxOnEscapePressed = function(self)
            StaticPopup_OnClick(self:GetParent(), 2)
        end
    }

    -- Refresh the menu after creating all elements
    RefreshPapaGreetMenu()
end

-- Toggle menu visibility
function TogglePapaGreetMenu()
    if not PapaGreetMenu then
        ShowPapaGreetMenu()
    else
        if PapaGreetMenu:IsShown() then
            PapaGreetMenu:Hide()
        else
            PapaGreetMenu:Show()
        end
    end
end
