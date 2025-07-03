local constants = require("constants")
local planner_name = "deconstruction-planner"

script.on_event(constants.mod_name .. "-hotkey", function(event) create_smart_deconstruction_planner(event) end)

function create_smart_deconstruction_planner(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end

    player.clear_cursor()
    -- Create the planner
    player.cursor_stack.set_stack { name = planner_name, count = 1 }
    player.cursor_stack_temporary = true
    local stack = player.cursor_stack
    if not (stack and stack.valid_for_read) then return end

    local selected = player.selected
    -- If there is an entity selected, set this as the filter. Otherwise, just create an empty deconstruction planner.
    if selected and selected.valid then
        -- Apply quality too if desired.
        local quality_mode = settings.get_player_settings(player)
            ["smart-deconstruction-planner-quality-mode"].value
        local quality
        if quality_mode == "matching quality" then
            quality = selected.quality
        else
            quality = nil
        end
        stack.set_entity_filter(1, { name = selected.name, type = selected.type, quality = quality })
        stack.entity_filter_mode = defines.deconstruction_item.entity_filter_mode.whitelist
    end
end
