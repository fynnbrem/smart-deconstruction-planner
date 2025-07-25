local const = require("const")

data:extend({
    {
        type = "string-setting",
        name = const.mod_name .. "-quality-mode",
        setting_type = "runtime-per-user",
        default_value = "any-quality",
        allowed_values = { "any-quality", "matching-quality" },
    },
    {
        type = "bool-setting",
        name = const.mod_name .. "-ghost-select-underlying",
        setting_type = "runtime-per-user",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = const.mod_name .. "-select-item-requests",
        setting_type = "runtime-per-user",
        default_value = true,
    }
})
