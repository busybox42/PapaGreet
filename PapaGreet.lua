local function Initialize()
  if not PapaGreetSavedVariables then
    PapaGreetSavedVariables = {
      profiles = {
        ["Default"] = {
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
            "wave",
            "crack",
            "cheer",
            "charge",
            "brandish",
            "bow",
            "hi",
            "hail",
            "nod",
            "grin"
          },
          goodbyeEmotes = {
            "drink",
            "wave",
            "cheer",
            "dance",
            "hug",
            "bow",
            "bye",
            "nod",
            "victory",
            "yay"
          },
          castBuff = "true",
          delayEmote = 3,
          delayLeave = 8,
        }
      },
      currentProfile = "Default"
    }
  end
  currentProfile = PapaGreetSavedVariables.currentProfile
end

Initialize()

-- Create a button with the name "PapaGreetButton"
local button = CreateFrame("Button", "PapaGreetButton", UIParent, "UIPanelButtonTemplate")
button:SetAttribute("type", "action")
button:SetAttribute("action", 1)

-- Set the size and text of the button
button:SetSize(40, 40)
button:SetNormalTexture(GetSpellTexture(226582))
button:SetPushedTexture(GetSpellTexture(226582))
button:SetDisabledTexture(GetSpellTexture(226582))

-- Position the button in the center of the screen
button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

-- Make the button movable, allow it to be moved off the screen, and ensure it is displayed above other frames
button:SetClampedToScreen(false)
button:SetMovable(true)
button:SetFrameStrata("HIGH")
button:SetAlpha(1)

-- Show the button
button:Show()

-- Define a function for moving the button when the middle mouse button is held down
local function moveButtonOnMiddleMouseDown(self)
  -- Start moving the button
  self:StartMoving()
end

-- Register the button's OnMouseUp and OnMouseDown events
button:SetScript("OnMouseUp", function(self, button)
  currentProfile = PapaGreetSavedVariables.currentProfile
  if IsMouseButtonDown("MiddleButton") then
    return
  end
  if button == "LeftButton" and IsShiftKeyDown() then
    ToggleLFDParentFrame()
  elseif button == "LeftButton" and IsControlKeyDown() then
    TogglePapaGreetMenu()
  elseif button == "RightButton" and IsShiftKeyDown() then
    TogglePVPUI()
  elseif button == "LeftButton" then
    -- Choose a random greeting and emote
    local greeting = PapaGreetSavedVariables.profiles[currentProfile].greetings[math.random(#PapaGreetSavedVariables.profiles[currentProfile].greetings)]
    local emote = PapaGreetSavedVariables.profiles[currentProfile].greetingEmotes[math.random(#PapaGreetSavedVariables.profiles[currentProfile].greetingEmotes)]
    -- Determine the appropriate chat channel to use
    local chatChannel
    if IsInGroup() then
      if IsInInstance() then
        chatChannel = "INSTANCE_CHAT"
      else
        chatChannel = "PARTY"
      end
    else
      chatChannel = "SAY"
    end

    -- Send the greeting and emote to the appropriate chat channel
    if greeting then
      SendChatMessage(greeting, chatChannel)
    end

    -- Perform the emote after a 2 second delay
    local function performEmote()
      if emote then
        DoEmote(emote)
      end
    end

    C_Timer.After(math.floor(PapaGreetSavedVariables.profiles[currentProfile].delayEmote), performEmote)

  elseif button == "RightButton" then

    local name, instanceType, difficultyID, LfgDungeonID = GetInstanceInfo()
    -- Choose a random goodbye and emote
    local goodbye = PapaGreetSavedVariables.profiles[currentProfile].goodbyes[math.random(#PapaGreetSavedVariables.profiles[currentProfile].goodbyes)]
    local emote = PapaGreetSavedVariables.profiles[currentProfile].goodbyeEmotes[math.random(#PapaGreetSavedVariables.profiles[currentProfile].goodbyeEmotes)]

    -- Determine the appropriate chat channel to use
    local chatChannel
    if IsInGroup() then
      if IsInInstance() then
        chatChannel = "INSTANCE_CHAT"
      else
          chatChannel = "PARTY"
      end
    else
      chatChannel = "SAY"
    end

    -- Send the goodbye and emote to the appropriate chat channel
    if goodbye then
      SendChatMessage(goodbye, chatChannel)
    end
    -- Perform the emote after a 2 second delay
    local function performEmote()
      if emote then
        DoEmote(emote)
      end
    end

    C_Timer.After(math.floor(PapaGreetSavedVariables.profiles[currentProfile].delayEmote), performEmote)

    local function leaveParty()
      C_PartyInfo.LeaveParty()
    end

    if LfgDungeonID ~= nil then
      C_Timer.After(math.floor(PapaGreetSavedVariables.profiles[currentProfile].delayLeave), leaveParty)
    end

  elseif button == "MiddleButton" then
    -- Stop moving the button
    self:StopMovingOrSizing()
  end
end)

button:SetScript("OnMouseDown", function(self, button)
  if button == "MiddleButton" then
    -- Move the button when the middle mouse button is held down
    moveButtonOnMiddleMouseDown(self)
  end
end)

-- Create the /papa command
SLASH_PAPA1 = '/papa'

-- Define a function to handle the /papa command
function SlashCmdList.PAPA(cmd)
  -- Split the command into arguments
  local args = {}
  for word in cmd:gmatch("%w+") do
    table.insert(args, word)
  end

  -- Get the first argument
  local command = args[1]

  local menu = 'closed'
  if command == 'menu' then
    -- Open the menu
    TogglePapaGreetMenu()
  elseif command == 'hide' then
    -- Hide the icon
    PapaGreetButton:Hide()
  elseif command == 'show' then
    -- Show the icon
    PapaGreetButton:Show()
  else
    print("Usage: /papa menu | hide | show")
  end
end
