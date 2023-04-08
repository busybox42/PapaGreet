-- Define a function to show the menu
function ShowPapaGreetMenu()

  -- Create the menu frame
  local menu = CreateFrame("Frame", "PapaGreetMenu", UIParent, "BasicFrameTemplate")
  menu:SetSize(350, 380)
  menu:SetPoint("CENTER")
  menu:SetFrameStrata("DIALOG")
  menu:SetMovable(true)

  -- Set the title of the menu
  local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", menu, "TOP", 0, -5)
  title:SetText("PapaGreet Menu")

  -- add mouse event handler
  menu:SetScript("OnMouseDown", function(self, button)
    if button == "MiddleButton" then
        self:StartMoving()
    end
  end)
  menu:SetScript("OnMouseUp", function(self, button)
      if button == "MiddleButton" then
          self:StopMovingOrSizing()
      end
  end)

  -- Define a function to load the saved variables and refresh the menu
function LoadPapaGreetSavedVariablesAndRefresh()
  -- Load the saved variables for the current profile
  PapaGreetSavedVariables = PapaGreetSavedVariables or {}
  PapaGreetSavedVariables.profiles = PapaGreetSavedVariables.profiles or {}
  PapaGreetSavedVariables.currentProfile = PapaGreetSavedVariables.currentProfile or DEFAULT_PROFILE
  currentProfile = PapaGreetSavedVariables.currentProfile

  -- Refresh the menu
  RefreshPapaGreetMenu()
end
  -- Create the profiles dropdown menu
  local profileDropdown = CreateFrame("Frame", "PapaGreetProfileDropdown", menu, "UIDropDownMenuTemplate")
  profileDropdown:SetPoint("TOPLEFT", menu, "TOPLEFT", 190, -30)

  -- Define a function to initialize the dropdown menu
  local function InitializeProfileDropdown(self, level)
    -- Get the list of profiles from the saved variables table
    local profiles = PapaGreetSavedVariables.profiles

    -- Add each profile to the dropdown menu
    for name, _ in pairs(profiles) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = name
        info.func = function()
          -- Set the current profile when the option is selected
          currentProfile = name
          PapaGreetSavedVariables.currentProfile = currentProfile
          UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
          LoadPapaGreetSavedVariablesAndRefresh()
        end
        UIDropDownMenu_AddButton(info, level)
    end
  end

  -- Set the initialize function for the dropdown menu
  UIDropDownMenu_Initialize(profileDropdown, InitializeProfileDropdown)

  -- Set the current selection for the dropdown menu
  UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)

  -- Create the "Create Profile" button
  local createProfileButton = CreateFrame("Button", "PapaGreetCreateProfileButton", menu, "GameMenuButtonTemplate")
  createProfileButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -220, -30)
  createProfileButton:SetSize(120, 27)
  createProfileButton:SetText("Create Profile")

  -- Attach a script to the button to handle clicks
  createProfileButton:SetScript("OnClick", function()
    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_CREATE_PROFILE")
  end)

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_CREATE_PROFILE"] = {
    text = "Enter a name for the new profile:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnShow = function(self)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      -- Get the name entered by the user
      local name = self.editBox:GetText()

      -- Add the new profile to the saved variables table
      PapaGreetSavedVariables.profiles[name] = {
          greetings = {},
          goodbyes = {},
          greetingEmotes = {},
          goodbyeEmotes = {}
      }

      -- Update the current profile
      currentProfile = name
      UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
    end,
    EditBoxOnEnterPressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 2)
    end
  }

  -- Create the "Delete Profile" button
  local deleteProfileButton = CreateFrame("Button", "PapaGreetDeleteProfileButton", menu, "GameMenuButtonTemplate")
  deleteProfileButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -220, -60)
  deleteProfileButton:SetSize(120, 27)
  deleteProfileButton:SetText("Delete Profile")

  -- Attach a script to the button to handle clicks
  deleteProfileButton:SetScript("OnClick", function()
    -- Make sure the default profile cannot be deleted
    if currentProfile == "Default" then
        print("The default profile cannot be deleted.")
        return
    end

    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_DELETE_PROFILE")
  end)

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete the current profile?",
    button1 = "Delete",
    button2 = "Cancel",
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnAccept = function()
      -- Delete the current profile from the saved variables table
      PapaGreetSavedVariables.profiles[currentProfile] = nil

      -- Update the current profile
      currentProfile = PapaGreetSavedVariables.currentProfile
      UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
    end
  }

  -- Create the "Copy Profile" button
  function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
  end

  local copyProfileButton = CreateFrame("Button", "PapaGreetCopyProfileButton", menu, "GameMenuButtonTemplate")
  copyProfileButton:SetPoint("TOPLEFT", menu, "TOPLEFT", 207, -60)
  copyProfileButton:SetSize(120, 27)
  copyProfileButton:SetText("Copy Profile")

  -- Attach a script to the button to handle clicks
  copyProfileButton:SetScript("OnClick", function()
    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_COPY_PROFILE")
  end)  

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_COPY_PROFILE"] = {
    text = "Enter a name for the new profile:",
    button1 = "Copy",
    button2 = "Cancel",
    hasEditBox = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnShow = function(self)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      -- Get the name entered by the user
      local name = self.editBox:GetText()

      -- Make sure the name is not already in use
      if PapaGreetSavedVariables.profiles[name] then
        print("A profile with that name already exists.")
        return
      end

      -- Add the new profile to the saved variables table
      PapaGreetSavedVariables.profiles[name] = deepcopy(PapaGreetSavedVariables.profiles[currentProfile])

      -- Update the current profile
      currentProfile = name
      UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
    end,
    EditBoxOnEnterPressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 2)
    end
  }

  -- Delete Greetings
  local deleteGreetingLabel = menu:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  deleteGreetingLabel:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -218, -145)
  deleteGreetingLabel:SetText("Delete Greeting:")

  -- Create the dropdown menu
  local deleteGreetingsDropdown = CreateFrame("Frame", "PapaGreetDeleteGreetingsDropdown", menu, "UIDropDownMenuTemplate")
  deleteGreetingsDropdown:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -315, -160)

  -- Define a function to initialize the dropdown menu
  local function InitializeDeleteGreetingsDropdown(self, level)
    -- Get the current greetings for the profile
    local greetings = PapaGreetSavedVariables.profiles[currentProfile].greetings

    -- Add each greeting to the dropdown menu
    for i, greeting in ipairs(greetings) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = greeting
        info.func = function()
            -- Remove the greeting from the list when the option is selected
            table.remove(greetings, i)
        end
        UIDropDownMenu_AddButton(info, level)
    end
  end

  -- Set the initialize function for the dropdown menu
  UIDropDownMenu_Initialize(deleteGreetingsDropdown, InitializeDeleteGreetingsDropdown)

  -- Create the "Add Greeting" button
  local addGreetingButton = CreateFrame("Button", "PapaGreetAddGreetingButton", menu, "GameMenuButtonTemplate")
  addGreetingButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -205, -110)
  addGreetingButton:SetSize(137, 30)
  addGreetingButton:SetText("Add Greeting")

  -- Attach a script to the button to handle clicks
  addGreetingButton:SetScript("OnClick", function()
    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_ADD_GREETING")
  end)

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_ADD_GREETING"] = {
    text = "Enter the greeting message:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnShow = function(self)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      -- Get the greeting message entered by the user
      local greeting = self.editBox:GetText()

      -- Add the greeting to the list for the current profile
      table.insert(PapaGreetSavedVariables.profiles[currentProfile].greetings, greeting)
    end,
    EditBoxOnEnterPressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 2)
    end
  }

  -- Delete Goodbyes
  local deleteGoodbyeLabel = menu:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  deleteGoodbyeLabel:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -38, -145)
  deleteGoodbyeLabel:SetText("Delete Goodbye:")

  -- Create the dropdown menu
  local deleteGoodbyesDropdown = CreateFrame("Frame", "PapaGreetDeleteGoodbyesDropdown", menu, "UIDropDownMenuTemplate")
  deleteGoodbyesDropdown:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -130, -160)

  -- Define a function to initialize the dropdown menu
  local function InitializeDeleteGoodbyesDropdown(self, level)
    -- Get the current goodbyes for the profile
    local goodbyes = PapaGreetSavedVariables.profiles[currentProfile].goodbyes

    -- Add each goodbye to the dropdown menu
    for i, goodbye in ipairs(goodbyes) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = goodbye
        info.func = function()
            -- Remove the goodbye from the list when the option is selected
            table.remove(goodbyes, i)
        end
        UIDropDownMenu_AddButton(info, level)
    end
  end

  -- Set the initialize function for the dropdown menu
  UIDropDownMenu_Initialize(deleteGoodbyesDropdown, InitializeDeleteGoodbyesDropdown)

  -- Create the "Add Goodbye" button
  local addGoodbyeButton = CreateFrame("Button", "PapaGreetAddGoodbyeButton", menu, "GameMenuButtonTemplate")
  addGoodbyeButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -20, -110)
  addGoodbyeButton:SetSize(137, 30)
  addGoodbyeButton:SetText("Add Goodbye")

  -- Attach a script to the button to handle clicks
  addGoodbyeButton:SetScript("OnClick", function()
    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_ADD_GOODBYE")
  end)

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_ADD_GOODBYE"] = {
    text = "Enter the goodbye message:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnShow = function(self)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      -- Get the goodbye message entered by the user
      local goodbye = self.editBox:GetText()

      -- Add the goodbye to the list for the current profile
      table.insert(PapaGreetSavedVariables.profiles[currentProfile].goodbyes, goodbye)
    end,
      EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
      end,
      EditBoxOnEscapePressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 2)
      end
    }

  -- Delete Greeting Emotes
  local deleteGreetingEmoteLabel = menu:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  deleteGreetingEmoteLabel:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -200, -245)
  deleteGreetingEmoteLabel:SetText("Delete Greeting Emote:")

  -- Create the dropdown menu
  local deleteGreetingEmotesDropdown = CreateFrame("Frame", "PapaGreetDeleteGreetingEmotesDropdown", menu, "UIDropDownMenuTemplate")
  deleteGreetingEmotesDropdown:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -315, -260)

  -- Define a function to initialize the dropdown menu
  local function InitializeDeleteGreetingEmotesDropdown(self, level)
    -- Get the current greeting emotes for the profile
    local greetingEmotes = PapaGreetSavedVariables.profiles[currentProfile].greetingEmotes

    -- Add each greeting emote to the dropdown menu
    for i, greetingEmote in ipairs(greetingEmotes) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = greetingEmote
        info.func = function()
            -- Remove the greeting emote from the list when the option is selected
            table.remove(greetingEmotes, i)
        end
        UIDropDownMenu_AddButton(info, level)
    end
  end

  -- Set the initialize function for the dropdown menu
  UIDropDownMenu_Initialize(deleteGreetingEmotesDropdown, InitializeDeleteGreetingEmotesDropdown)

  -- Create the "Add Greeting Emote" button
  local addGreetingEmoteButton = CreateFrame("Button", "PapaGreetAddGreetingEmoteButton", menu, "GameMenuButtonTemplate")
  addGreetingEmoteButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -200, -205)
  addGreetingEmoteButton:SetSize(140, 34)
  addGreetingEmoteButton:SetText("Add Greeting Emote")

  -- Attach a script to the button to handle clicks
  addGreetingEmoteButton:SetScript("OnClick", function()
    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_ADD_GREETING_EMOTE")
  end)

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_ADD_GREETING_EMOTE"] = {
    text = "Enter the greeting emote:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnShow = function(self)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      -- Get the goodbye emote entered by the user
      local greetingEmote = self.editBox:GetText()

      -- Add the goodbye emote to the list for the current profile
      table.insert(PapaGreetSavedVariables.profiles[currentProfile].greetingEmotes, greetingEmote)
    end,
    EditBoxOnEnterPressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 2)
    end
  }

-- Delete Goodbye Emotes
  local deleteGoodbyeEmotesLabel = menu:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  deleteGoodbyeEmotesLabel:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -18, -245)
  deleteGoodbyeEmotesLabel:SetText("Delete Goodbye Emote:")

  -- Create the dropdown menu
  local deleteGoodbyeEmotesDropdown = CreateFrame("Frame", "PapaGreetDeleteGoodbyeEmotesDropdown", menu, "UIDropDownMenuTemplate")
  deleteGoodbyeEmotesDropdown:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -130, -260)

  -- Define a function to initialize the dropdown menu
  local function InitializeDeleteGoodbyeEmotesDropdown(self, level)
    -- Get the current goodbye emotes for the profile
    local goodbyeEmotes = PapaGreetSavedVariables.profiles[currentProfile].goodbyeEmotes

    -- Add each goodbye emote to the dropdown menu
    for i, goodbyeEmote in ipairs(goodbyeEmotes) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = goodbyeEmote
      info.func = function()
          -- Remove the goodbye emote from the list when the option is selected
          table.remove(goodbyeEmotes, i)
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end

  -- Set the initialize function for the dropdown menu
  UIDropDownMenu_Initialize(deleteGoodbyeEmotesDropdown, InitializeDeleteGoodbyeEmotesDropdown)

  -- Create the "Add Goodbye Emote" button
  local addGoodbyeEmoteButton = CreateFrame("Button", "PapaGreetAddGoodbyeEmoteButton", menu, "GameMenuButtonTemplate")
  addGoodbyeEmoteButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -20, -205)
  addGoodbyeEmoteButton:SetSize(140, 34)
  addGoodbyeEmoteButton:SetText("Add Goodbye Emote")

  -- Attach a script to the button to handle clicks
  addGoodbyeEmoteButton:SetScript("OnClick", function()
    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_ADD_GOODBYE_EMOTE")
  end)

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_ADD_GOODBYE_EMOTE"] = {
    text = "Enter the goodbye emote:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnShow = function(self)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      -- Get the goodbye emote entered by the user
      local goodbyeEmote = self.editBox:GetText()

      -- Add the goodbye emote to the list for the current profile
      table.insert(PapaGreetSavedVariables.profiles[currentProfile].goodbyeEmotes, goodbyeEmote)
    end,
    EditBoxOnEnterPressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
      StaticPopup_OnClick(self:GetParent(), 2)
    end
  }

  -- Create the Delay (seconds) label
  local delayLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  delayLabel:SetPoint("TOPRIGHT", -200, -300)
  delayLabel:SetText("Emote Delay (seconds):")

  -- Create the Delay (seconds) EditBox
  local delayEditBox = CreateFrame("EditBox", "PapaGreetDelayEditBox", menu, "InputBoxTemplate")
  delayEditBox:SetSize(20, 25)
  delayEditBox:SetPoint("LEFT", delayLabel, "RIGHT", 10, 0)
  delayEditBox:SetNumeric(true)
  delayEditBox:SetMaxLetters(2)
  delayEditBox:SetAutoFocus(false)
  delayEditBox:SetText(math.floor(PapaGreetSavedVariables.profiles[currentProfile].delayEmote))

  -- Function to save the integer value when the user pushes Enter or closes the menu
  local function saveDelayValue()
    local inputValue = tonumber(delayEditBox:GetText())
    if inputValue then
      -- Save the value as an integer
      local delayEmote = math.floor(inputValue)
      PapaGreetSavedVariables.profiles[currentProfile].delayEmote = delayEmote
    end
  end

  -- Register the script to save the value when the user pushes Enter
  delayEditBox:SetScript("OnEnterPressed", function(self)
    saveDelayValue()
    self:ClearFocus()
  end)

  -- Create the Delay (seconds) label for leaving
  local leaveDelayLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  leaveDelayLabel:SetPoint("TOPRIGHT", -200, -320)
  leaveDelayLabel:SetText("Leave Delay (seconds): ")

  -- Create the Delay (seconds) EditBox for leaving
  local leaveDelayEditBox = CreateFrame("EditBox", "PapaGreetLeaveDelayEditBox", menu, "InputBoxTemplate")

  leaveDelayEditBox:SetSize(20, 25)
  leaveDelayEditBox:SetPoint("LEFT", leaveDelayLabel, "RIGHT", 10, 0)
  leaveDelayEditBox:SetNumeric(true)
  leaveDelayEditBox:SetMaxLetters(2)
  leaveDelayEditBox:SetAutoFocus(false)
  leaveDelayEditBox:SetText(math.floor(PapaGreetSavedVariables.profiles[currentProfile].delayLeave))

  -- Function to save the integer value when the user pushes Enter or closes the menu for leaving
  local function saveLeaveDelayValue()
    local inputValue = tonumber(leaveDelayEditBox:GetText())
    if inputValue then
      -- Save the value as an integer
      local delayLeave = math.floor(inputValue)
      PapaGreetSavedVariables.profiles[currentProfile].delayLeave = delayLeave
    end
  end

  -- Register the script to save the value when the user pushes Enter for leaving
  leaveDelayEditBox:SetScript("OnEnterPressed", function(self)
    saveLeaveDelayValue()
    self:ClearFocus()
  end)

end

local show
function TogglePapaGreetMenu()
  if show == nil then
    ShowPapaGreetMenu()
    show = 1
  else  
    if PapaGreetMenu:IsShown() then
      PapaGreetMenu:Hide()
    else
      PapaGreetMenu:Show()
    end
  end
end

-- Define a function to refresh the PapaGreetMenu frame
function RefreshPapaGreetMenu()
  -- Get the current profile from the saved variables
  local currentProfile = PapaGreetSavedVariables.currentProfile

  -- Refresh the Delay (seconds) EditBox for emotes
  local emoteDelayEditBox = _G["PapaGreetDelayEditBox"]
  emoteDelayEditBox:SetText(math.floor(PapaGreetSavedVariables.profiles[currentProfile].delayEmote))

  -- Refresh the Delay (seconds) EditBox for leaving
  local leaveDelayEditBox = _G["PapaGreetLeaveDelayEditBox"]
  leaveDelayEditBox:SetText(math.floor(PapaGreetSavedVariables.profiles[currentProfile].delayLeave))

  -- Refresh the profiles dropdown menu
  UIDropDownMenu_SetSelectedValue(PapaGreetProfileDropdown, currentProfile)
end