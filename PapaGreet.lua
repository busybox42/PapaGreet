-- Includes
local function Initialize()
  include("PapaGreetMenu.lua")
end

-- Create a button with the name "PapaGreetButton"
local button = CreateFrame("Button", "PapaGreetButton", UIParent, "UIPanelButtonTemplate")

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
  if IsMouseButtonDown("MiddleButton") then
    return
  end  
  if button == "LeftButton" then
    -- Choose a random greeting and emote
    local greeting = _G.profiles[_G.currentProfile].greetings[math.random(#_G.profiles[_G.currentProfile].greetings)]
    local emote = _G.profiles[_G.currentProfile].greetingEmotes[math.random(#_G.profiles[_G.currentProfile].greetingEmotes)]

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
    SendChatMessage(greeting, chatChannel)

    -- Perform the emote after a 2 second delay
    local function performEmote()
      DoEmote(emote)
    end

    C_Timer.After(3, performEmote)
  elseif button == "RightButton" then
    -- Choose a random goodbye and emote
    local goodbye = _G.profiles[_G.currentProfile].goodbyes[math.random(#_G.profiles[_G.currentProfile].goodbyes)]
    local emote = _G.profiles[_G.currentProfile].goodbyeEmotes[math.random(#_G.profiles[_G.currentProfile].goodbyeEmotes)]

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
    SendChatMessage(goodbye, chatChannel)

    -- Perform the emote after a 2 second delay
    local function performEmote()
      DoEmote(emote)
    end

    C_Timer.After(3, performEmote)
  elseif button == "MiddleButton" then
    -- Stop moving the button
    self:StopMovingOrSizing()
  end
end)

button:SetScript("OnMouseDown", function(self, button)
  if button == "MiddleButton" then
  -- Move the button when the middle mouse button is held down
  moveButtonOnMiddleMouseDown(self)
  else
  -- Perform the left or right button action immediately
  button:GetScript("OnMouseUp")(self, button)
  end
end)

Initialize()
