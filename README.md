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
- Configure cooldown (time between greeting/goodbye uses, 0 to disable)

### Cooldown System

PapaGreet includes an optional cooldown system to prevent accidental spam:
- **Visual cooldown spiral** on the button shows remaining cooldown time
- **Configurable delay** (default 3 seconds, 0 to disable)
- **Per-profile settings** - each profile can have its own cooldown
- **Shake feedback** when attempting to use during cooldown

### Slash Commands

Type `/papa` to see all available commands:

- `/papa greet` - Send greeting now
- `/papa bye` - Send goodbye and start leave timer
- `/papa cancel` - Cancel the pending leave action
- `/papa menu` - Toggle the settings menu
- `/papa hide` - Hide the button
- `/papa show` - Show the button
- `/papa reset` - Reset button position to center
- `/papa cd [seconds]` - Set cooldown (0=off)
- `/papa version` - Show addon version

### Keybindings

PapaGreet supports custom keybindings that can be configured in the WoW keybinding menu (ESC → Keybinds → PapaGreet):

- **Send Greeting** - Trigger a greeting without clicking the button
- **Send Goodbye & Leave** - Trigger goodbye and leave timer without clicking
- **Cancel Leave** - Cancel the pending leave action
- **Toggle Menu** - Open/close the settings menu

### Visual Countdown

When you trigger a goodbye, a countdown timer appears on the button showing seconds remaining before auto-leaving the group. This gives you a clear visual indicator and time to cancel if needed.

### Combat-Safe Queueing

If you try to send a greeting while in combat, it will be automatically queued and sent when you leave combat. You'll see a notification that the greeting was queued, and another when it's sent after combat ends.

### Future-Proof Architecture

PapaGreet includes an API abstraction layer that automatically detects and uses newer WoW APIs when available (like those coming in the Midnight expansion), while falling back gracefully to current APIs on older versions. This ensures the addon will work seamlessly across WoW updates.

## License

PapaGreet is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

