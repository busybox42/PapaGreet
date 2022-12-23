-- Define a function to show the menu
function ShowPapaGreetMenu()
  -- Create the menu frame
  local menu = CreateFrame("Frame", "PapaGreetMenu", UIParent, "BasicFrameTemplate")
  menu:SetSize(350, 300)
  menu:SetPoint("CENTER")
  menu:SetFrameStrata("DIALOG")

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
            UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
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
      currentProfile = "Default"
      UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
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
  addGreetingButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -200, -110)
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
  addGreetingEmoteButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -200, -210)
  addGreetingEmoteButton:SetSize(137, 30)
  addGreetingEmoteButton:SetText("Add Greeting Emote")

  -- Attach a script to the button to handle clicks
  addGreetingEmoteButton:SetScript("OnClick", function()
    -- Show the pop-up window
    StaticPopup_Show("PAPA_GREET_ADD_GREETING_EMOTE")
  end)

  -- Create the pop-up window
  StaticPopupDialogs["PAPA_GREET_DELETE_GREETING_EMOTE"] = {
    text = "Enter the greeting emote to delete:",
    button1 = "Delete",
    button2 = "Cancel",
    hasEditBox = 1,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    OnShow = function(self)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      -- Get the greeting emote entered by the user
      local greetingEmote = self.editBox:GetText()
    
      -- Get the current greeting emotes for the profile
      local greetingEmotes = PapaGreetSavedVariables.profiles[currentProfile].greetingEmotes
    
      -- Find the index of the greeting emote in the list
      local index = table.find(greetingEmotes, greetingEmote)
    
      -- Remove the greeting emote from the list if it was found
      if index then
        table.remove(greetingEmotes, index)
      end
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
  addGoodbyeEmoteButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -20, -210)
  addGoodbyeEmoteButton:SetSize(137, 30)
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

end

-- Define a function to toggle the menu
function TogglePapaGreetMenu(menu)
  -- Toggle the visibility of the menu
  menu:SetShown(not menu:IsShown())
end

-- Create the menu frame and store it in a global variable
globalMenu = ShowPapaGreetMenu()

-- Register the /papa command to toggle the menu
SLASH_PAPA1 = "/papa"
function SlashCmdList.PAPA(msg, editbox)
  TogglePapaGreetMenu()
end

-- Define a function to toggle the menu
local menuIsOpen = false
function TogglePapaGreetMenu()
  if menuIsOpen then
    -- Close the menu if it is open
    PapaGreetMenu:Hide()
    menuIsOpen = false
  else
    -- Open the menu if it is closed
    PapaGreetMenu:Show()
    menuIsOpen = true
  end
end

PapaGreetMenu:Hide()