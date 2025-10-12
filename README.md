# PapaGreet

PapaGreet is a World of Warcraft addon that automates greetings and farewells in groups with customizable messages and emotes.

## Installation

To install PapaGreet, follow these steps:

1. Download the PapaGreet.zip file from the releases page.
2. Extract the contents of the zip file to your World of Warcraft `Interface/AddOns` directory.
3. Restart World of Warcraft or use the `/reload` command to load the addon.

## Usage

PapaGreet adds a movable button to your screen with the following controls:

### Button Controls

- **Left Click**: Send a random greeting and emote
- **Right Click**: Send a random goodbye, emote, and leave the group after a delay
- **Ctrl+Left Click**: Open the settings menu
- **Ctrl+Right Click**: Cancel the pending leave group action
- **Shift+Left Click**: Open the LFD (Dungeon Finder) interface
- **Shift+Right Click**: Open the PVP interface
- **Middle Mouse Drag**: Move the button (position is saved)

### Chat Channels

Messages are automatically sent to the appropriate channel:
- **Party**: When in a dungeon/raid group
- **Instance Chat**: When in instanced content
- **Say**: When solo

### Settings Menu

Access the settings menu with **Ctrl+Left Click** or the `/papa menu` command.

From the menu you can:
- Create, delete, and copy profiles
- Add/remove custom greetings and goodbyes
- Add/remove custom emotes for greetings and goodbyes
- Adjust emote delay (time between message and emote)
- Adjust leave delay (time between goodbye and leaving group)

### Slash Commands

- `/papa menu` - Toggle the settings menu
- `/papa show` - Show the button
- `/papa hide` - Hide the button

### Keybindings

PapaGreet supports custom keybindings that can be configured in the WoW keybinding menu (ESC → Keybinds → PapaGreet):

- **Send Greeting** - Trigger a greeting without clicking the button
- **Send Goodbye & Leave** - Trigger goodbye and leave timer without clicking
- **Cancel Leave** - Cancel the pending leave action
- **Toggle Menu** - Open/close the settings menu

### Visual Countdown

When you trigger a goodbye, a countdown timer appears on the button showing seconds remaining before auto-leaving the group. This gives you a clear visual indicator and time to cancel if needed.

## License

PapaGreet is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

