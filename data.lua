local graphics_dir = "__personal-trains__/graphics"

data:extend {
  {
    type = "custom-input",
    name = "personal-trains-call-hotkey",
    key_sequence = "SHIFT + J",
    consuming = "game-only",
    action = "lua",
    enabled_while_spectating = false,
    enabled_while_in_cutscene = false,
  },
  {
    type = "shortcut",
    name = "personal-trains-call-shortcut",
    associated_control_input = "personal-trains-call-hotkey",
    action = "lua",
    toggleable = false,
    order = "personal-trains-call-shortcut",
    icon = graphics_dir .. "/call.png",
    small_icon = graphics_dir .. "/call.png",
    localised_name = { "shortcut-name.personal-trains-call-shortcut" },
    localised_description = { "shortcut-description.personal-trains-call-shortcut" },
  },
  {
    type = "custom-input",
    name = "personal-trains-schedule-hotkey",
    key_sequence = "CONTROL + J",
    consuming = "game-only",
    action = "lua",
    enabled_while_spectating = false,
    enabled_while_in_cutscene = false,
  },
  {
    type = "shortcut",
    name = "personal-trains-schedule-shortcut",
    associated_control_input = "personal-trains-schedule-hotkey",
    action = "lua",
    toggleable = false,
    order = "personal-trains-schedule",
    icon = graphics_dir .. "/schedule.png",
    small_icon = graphics_dir .. "/schedule.png",
    localised_name = { "shortcut-name.personal-trains-schedule-shortcut" },
    localised_description = { "shortcut-description.personal-trains-schedule-shortcut" },
  },
  {
    type = "sprite",
    name = "personal-trains-call-icon",
    filename = graphics_dir .. "/call_colored.png",
    size = 64,
    scale = 2,
    mipmap_count = 4,
    flags = { "gui-icon" }
  },
}

