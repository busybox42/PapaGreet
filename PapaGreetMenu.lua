-- PapaGreetMenu.lua
-- Version: 1.2.2 - Debug Version

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
local MAX_MESSAGE_LENGTH = 255
local MAX_EMOTE_LENGTH = 50
local MAX_PROFILE_NAME_LENGTH = 50

-- Input sanitization utility
local function sanitizeInput(input, maxLength)
    if not input then return nil end
    -- Trim whitespace
    input = input:match("^%s*(.-)%s*$")
    -- Check if empty after trimming
    if input == "" then return nil end
    -- Truncate if too long
    if #input > maxLength then
        input = input:sub(1, maxLength)
    end
    return input
end

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
    }
    PapaGreetSavedVariables.currentProfile = PapaGreetSavedVariables.currentProfile or DEFAULT_PROFILE
    
    -- Ensure all profiles have necessary fields
    for name, profile in pairs(PapaGreetSavedVariables.profiles) do
        profile.greetings = profile.greetings or {}
        profile.goodbyes = profile.goodbyes or {}
        profile.greetingEmotes = profile.greetingEmotes or {}
        profile.goodbyeEmotes = profile.goodbyeEmotes or {}
        profile.delayEmote = profile.delayEmote or 3
        profile.delayLeave = profile.delayLeave or 8
        profile.cooldown = profile.cooldown or 3
    end
end

InitializeVariables()
local currentProfile = PapaGreetSavedVariables.currentProfile

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
    
    local cooldownEditBox = _G["PapaGreetCooldownEditBox"]
    if cooldownEditBox then
        cooldownEditBox:SetText(math_floor(PapaGreetSavedVariables.profiles[currentProfile].cooldown or 3))
    end
    
    UIDropDownMenu_SetSelectedValue(PapaGreetProfileDropdown, currentProfile)
end

-- Helper function to create buttons
local function createButton(name, parent, point, offsetX, offsetY, width, height, text, popup)
    print("PapaGreet DEBUG: Creating button: " .. name .. " with text: " .. text)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetPoint(point, offsetX, offsetY)
    btn:SetSize(width, height)
    btn:SetText(text)
    
    -- Test if button was created properly
    print("PapaGreet DEBUG: Button created - Name: " .. (btn:GetName() or "nil") .. ", Text: " .. (btn:GetText() or "nil"))
    
    -- Test if button is interactive
    btn:SetScript("OnEnter", function()
        print("PapaGreet DEBUG: Mouse entered button: " .. text)
    end)
    
    btn:SetScript("OnClick", function()
        print("PapaGreet DEBUG: ===== BUTTON CLICKED =====")
        print("PapaGreet DEBUG: Button text: " .. text)
        print("PapaGreet DEBUG: Popup: " .. tostring(popup))
        print("PapaGreet DEBUG: Current profile: " .. tostring(currentProfile))
        print("PapaGreet DEBUG: Button enabled: " .. tostring(btn:IsEnabled()))
        print("PapaGreet DEBUG: Button visible: " .. tostring(btn:IsVisible()))
        print("PapaGreet DEBUG: Button shown: " .. tostring(btn:IsShown()))
        
        -- Test if ANY button click works
        if text == "Create Profile" then
            print("PapaGreet DEBUG: CREATE PROFILE BUTTON CLICKED!")
        end
        
        -- Check if trying to modify Default profile
        if currentProfile == DEFAULT_PROFILE and (popup == "PAPA_GREET_ADD_GREETING" or 
           popup == "PAPA_GREET_ADD_GOODBYE" or popup == "PAPA_GREET_ADD_GREETING_EMOTE" or 
           popup == "PAPA_GREET_ADD_GOODBYE_EMOTE") then
            UIErrorsFrame:AddMessage("Cannot modify Default profile. Create a new profile first.", 1.0, 0.0, 0.0)
            return
        end
        
        if popup then
            print("PapaGreet DEBUG: Attempting to show popup: " .. popup)
            if StaticPopupDialogs[popup] then
                print("PapaGreet DEBUG: Popup definition found!")
                
                -- Hide any existing dialogs first
                StaticPopup_Hide(popup)
                
                -- Force the dialog to appear
                local dialog = StaticPopup_Show(popup)
                if dialog then
                    print("PapaGreet DEBUG: Popup shown successfully")
                    print("PapaGreet DEBUG: Dialog frame strata: " .. dialog:GetFrameStrata())
                    print("PapaGreet DEBUG: Dialog is shown: " .. tostring(dialog:IsShown()))
                    dialog:Raise()
                else
                    print("PapaGreet ERROR: StaticPopup_Show returned nil!")
                    print("PapaGreet DEBUG: Checking for conflicts...")
                    for i = 1, 4 do
                        local activeDialog = _G["StaticPopup" .. i]
                        if activeDialog and activeDialog:IsShown() then
                            print("  StaticPopup" .. i .. " is already shown: " .. tostring(activeDialog.which))
                        end
                    end
                end
            else
                print("PapaGreet ERROR: Popup " .. popup .. " not found in StaticPopupDialogs!")
                print("PapaGreet DEBUG: Available popups:")
                for k, v in pairs(StaticPopupDialogs) do
                    if k:match("PAPA_GREET") then
                        print("  - " .. k)
                    end
                end
            end
        else
            print("PapaGreet ERROR: No popup name provided!")
        end
    end)
    return btn
end

-- Helper function to create dropdown menus for deleting items
local function createDeleteDropdown(name, parent, point, offsetX, offsetY, width, itemsKey, label)
    -- Create label
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint(point, parent, point, offsetX, offsetY)
    labelText:SetText(label)
    
    -- Create dropdown below the label
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint(point, parent, point, offsetX - 15, offsetY - 25)
    dropdown:SetSize(width, 25)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        if currentProfile == DEFAULT_PROFILE then
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Cannot modify Default profile"
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
            return
        end
        
        local items = PapaGreetSavedVariables.profiles[currentProfile][itemsKey]
        if #items == 0 then
            local info = UIDropDownMenu_CreateInfo()
            info.text = "No items to delete"
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
            return
        end
        
        for i, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item
            info.func = function()
                table_remove(items, i)
                RefreshPapaGreetMenu()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Set button text
    UIDropDownMenu_SetText(dropdown, "Select to Delete")
    
    return dropdown
end

-- Define Static Popups (must be defined before ShowPapaGreetMenu)
StaticPopupDialogs["PAPA_GREET_CREATE_PROFILE"] = {
    text = "Enter the name for the new profile:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        self:SetFrameLevel(1000)
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        self:SetScale(1.0)
        self:Show()
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        if editBox then
            editBox:SetText("")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        -- For StaticPopup dialogs, the text is in self.data if we pass it,
        -- or we need to get it from the wndchild1 (editBox1)
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        local editBoxText = editBox and editBox:GetText() or ""
        
        local profileName = sanitizeInput(editBoxText, MAX_PROFILE_NAME_LENGTH)
        print("PapaGreet DEBUG: After sanitize: " .. tostring(profileName))
        
        if profileName then
            if PapaGreetSavedVariables.profiles[profileName] then
                print("Profile '" .. profileName .. "' already exists.")
            else
                print("PapaGreet DEBUG: Creating new profile: " .. profileName)
                PapaGreetSavedVariables.profiles[profileName] = deepcopy(PapaGreetSavedVariables.profiles[currentProfile])
                currentProfile = profileName
                PapaGreetSavedVariables.currentProfile = currentProfile
                print("PapaGreet DEBUG: About to refresh menu")
                RefreshPapaGreetMenu()
                print("Profile '" .. profileName .. "' created.")
            end
        else
            print("Profile name cannot be empty or contain only whitespace.")
        end
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 2)
    end
}

StaticPopupDialogs["PAPA_GREET_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete the current profile?",
    button1 = "Delete",
    button2 = "Cancel",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
    end,
    OnAccept = function(self)
        if currentProfile == DEFAULT_PROFILE then
            print("Cannot delete the Default profile.")
            return
        end
        local deletedProfile = currentProfile
        PapaGreetSavedVariables.profiles[currentProfile] = nil
        currentProfile = DEFAULT_PROFILE
        PapaGreetSavedVariables.currentProfile = currentProfile
        RefreshPapaGreetMenu()
        print("Profile '" .. deletedProfile .. "' deleted.")
    end
}

StaticPopupDialogs["PAPA_GREET_COPY_PROFILE"] = {
    text = "Enter the name for the copied profile:",
    button1 = "Copy",
    button2 = "Cancel",
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        if editBox then
            editBox:SetText(currentProfile .. " Copy")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        local editBoxText = editBox and editBox:GetText() or ""
        local profileName = sanitizeInput(editBoxText, MAX_PROFILE_NAME_LENGTH)
        if profileName then
            if PapaGreetSavedVariables.profiles[profileName] then
                print("Profile '" .. profileName .. "' already exists.")
            else
                PapaGreetSavedVariables.profiles[profileName] = deepcopy(PapaGreetSavedVariables.profiles[currentProfile])
                print("Profile '" .. profileName .. "' created as a copy of '" .. currentProfile .. "'.")
                RefreshPapaGreetMenu()
            end
        else
            print("Profile name cannot be empty or contain only whitespace.")
        end
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 2)
    end
}

StaticPopupDialogs["PAPA_GREET_ADD_GREETING"] = {
    text = "Enter the greeting message:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        if editBox then
            editBox:SetText("")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        local editBoxText = editBox and editBox:GetText() or ""
        local greeting = sanitizeInput(editBoxText, MAX_MESSAGE_LENGTH)
        if greeting then
            table_insert(PapaGreetSavedVariables.profiles[currentProfile].greetings, greeting)
            RefreshPapaGreetMenu()
        else
            print("Greeting cannot be empty or contain only whitespace.")
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
    preferredIndex = 3,
    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        if editBox then
            editBox:SetText("")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        local editBoxText = editBox and editBox:GetText() or ""
        local goodbye = sanitizeInput(editBoxText, MAX_MESSAGE_LENGTH)
        if goodbye then
            table_insert(PapaGreetSavedVariables.profiles[currentProfile].goodbyes, goodbye)
            RefreshPapaGreetMenu()
        else
            print("Goodbye cannot be empty or contain only whitespace.")
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
    preferredIndex = 3,
    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        if editBox then
            editBox:SetText("")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        local editBoxText = editBox and editBox:GetText() or ""
        local emote = sanitizeInput(editBoxText, MAX_EMOTE_LENGTH)
        if emote then
            table_insert(PapaGreetSavedVariables.profiles[currentProfile].greetingEmotes, emote)
            RefreshPapaGreetMenu()
        else
            print("Greeting emote cannot be empty or contain only whitespace.")
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
    preferredIndex = 3,
    OnShow = function(self)
        self:SetFrameStrata("TOOLTIP")
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        if editBox then
            editBox:SetText("")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        local editBox = _G[self:GetName().."EditBox"] or _G[self:GetName().."WideEditBox"]
        local editBoxText = editBox and editBox:GetText() or ""
        local emote = sanitizeInput(editBoxText, MAX_EMOTE_LENGTH)
        if emote then
            table_insert(PapaGreetSavedVariables.profiles[currentProfile].goodbyeEmotes, emote)
            RefreshPapaGreetMenu()
        else
            print("Goodbye emote cannot be empty or contain only whitespace.")
        end
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 2)
    end
}

-- Show the menu
function ShowPapaGreetMenu()
    -- Reuse existing frame if it exists
    if PapaGreetMenu then
        PapaGreetMenu:Show()
        RefreshPapaGreetMenu()
        return
    end
    
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
    local function createDelay(labelText, editBoxName, yOffset, configKey, defaultValue)
        local label = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", menu, "TOPLEFT", 20, yOffset)
        label:SetText(labelText)

        local editBox = CreateFrame("EditBox", editBoxName, menu, "InputBoxTemplate")
        editBox:SetSize(50, 25)
        editBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
        editBox:SetNumeric(true)
        editBox:SetMaxLetters(2)
        editBox:SetAutoFocus(false)
        editBox:SetText(math_floor(PapaGreetSavedVariables.profiles[currentProfile][configKey] or defaultValue))

        editBox:SetScript("OnEnterPressed", function(self)
            local inputValue = tonumber(self:GetText())
            if inputValue then
                PapaGreetSavedVariables.profiles[currentProfile][configKey] = math_floor(inputValue)
                RefreshPapaGreetMenu()
            else
                print("Invalid input for " .. configKey)
            end
            self:ClearFocus()
        end)
    end

    -- Create Delay EditBoxes
    createDelay("Emote Delay (seconds):", "PapaGreetDelayEditBox", -120, "delayEmote", 3)
    createDelay("Leave Delay (seconds):", "PapaGreetLeaveDelayEditBox", -160, "delayLeave", 8)
    createDelay("Cooldown (seconds, 0=off):", "PapaGreetCooldownEditBox", -200, "cooldown", 3)

    -- Create Add Greeting Button and Delete Greeting Dropdown
    createButton("PapaGreetAddGreetingButton", menu, "TOPLEFT", 20, -240, 140, 27, "Add Greeting", "PAPA_GREET_ADD_GREETING")
    createDeleteDropdown("PapaGreetDeleteGreetingDropdown", menu, "TOPLEFT", 180, -240, 140, "greetings", "Delete Greeting:")

    -- Create Add Goodbye Button and Delete Goodbye Dropdown
    createButton("PapaGreetAddGoodbyeButton", menu, "TOPLEFT", 20, -280, 140, 27, "Add Goodbye", "PAPA_GREET_ADD_GOODBYE")
    createDeleteDropdown("PapaGreetDeleteGoodbyeDropdown", menu, "TOPLEFT", 180, -280, 140, "goodbyes", "Delete Goodbye:")

    -- Create Add Greeting Emote Button and Delete Greeting Emote Dropdown
    createButton("PapaGreetAddGreetingEmoteButton", menu, "TOPLEFT", 20, -320, 140, 27, "Add Greeting Emote", "PAPA_GREET_ADD_GREETING_EMOTE")
    createDeleteDropdown("PapaGreetDeleteGreetingEmoteDropdown", menu, "TOPLEFT", 180, -320, 140, "greetingEmotes", "Delete Greeting Emote:")

    -- Create Add Goodbye Emote Button and Delete Goodbye Emote Dropdown
    createButton("PapaGreetAddGoodbyeEmoteButton", menu, "TOPLEFT", 20, -360, 140, 27, "Add Goodbye Emote", "PAPA_GREET_ADD_GOODBYE_EMOTE")
    createDeleteDropdown("PapaGreetDeleteGoodbyeEmoteDropdown", menu, "TOPLEFT", 180, -360, 140, "goodbyeEmotes", "Delete Goodbye Emote:")

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
