local const = require("const")

local deconstruction_pre_planner = const.mod_name .. "-deconstruction-pre-planner"
local deconstruction_select = {
    border_color = { 247, 99, 0 },
    count_button_color = { 255, 136, 0 },
    mode = { "deconstruct" },
    cursor_box_type = "entity",
    started_sound = { filename = "__core__/sound/deconstruct-select-start.ogg" },
    ended_sound = { filename = "__core__/sound/deconstruct-select-end.ogg" }
}
-- TODO: Remove the hotkey for release, it is not implemented yet.
data:extend {
    {
        type = "custom-input",
        name = const.mod_name .. "-hotkey",
        key_sequence = "CONTROL + D",
    },
    {
        type = "shortcut",
        name = "my-selection-tool-shortcut",
        icons = {
            {
                icon = "__base__/graphics/icons/shortcut-toolbar/mip/new-deconstruction-planner-x56.png",
                icon_size = 56,
            },
            {
                icon = "__base__/graphics/icons/shapes/shape-circle.png",
                scale = 0.2,
            },
        },
        small_icons = {
            {
                icon = "__base__/graphics/icons/shortcut-toolbar/mip/new-deconstruction-planner-x24.png",
                icon_size = 24,
            },
            {
                icon = "__base__/graphics/icons/shapes/shape-circle.png",
                size = 24,
                scale = 0.2,
            },
        },
        style = "red",
        action = "spawn-item",
        item_to_spawn = deconstruction_pre_planner,
        order = "b[blueprints]-j[deconstruction-pre-planner]",
        technology_to_unlock = "construction-robotics",
        associated_control_input = const.mod_name .. "-hotkey",

    },
    {
        type = "selection-tool",
        name = deconstruction_pre_planner,
        icons = {
            {
                icon = const.mod_folder .. "/graphics/icons/deconstruction-pre-planner.png",
                scale = 1,
            },
        },
        subgroup = "tool",
        order = "c[automated-construction]-c[deconstruction-pre-planner]",
        stack_size = 1,
        flags = { "only-in-cursor", "spawnable" },
        select = deconstruction_select,
        alt_select = deconstruction_select,
    }

}
