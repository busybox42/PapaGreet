-- PapaGreetMenu.lua
_G.isMenuOpen = false
_G.currentProfile = "default"

-- Define the profiles table as a global variable
_G.profiles = {
  default = {
    greetings = {
      "Hail, champions!",
      "Greetings, heros!",
      "Greetings!",
      "Salutations, adventurers!",
      "Well met!",
      "Good evening!"
    },
    goodbyes = {
      "Farewell, champions. May your blade be sharp and your armor strong.",
      "Until we meet again, heros.",
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
    }
  }
}
