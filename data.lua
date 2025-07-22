local const = require("const")

data:extend {
    {
        type = "custom-input",
        name = const.mod_name .. "-hotkey",
        key_sequence = "CONTROL + D",
    },
    {
        type = "custom-input",
        name = "alt-click-iron-action",
        key_sequence = "ALT + mouse-button-1",
        -- "none" means the game still processes the key as usual;
        -- your script also receives the event.
        consuming = "none"
    }

}
