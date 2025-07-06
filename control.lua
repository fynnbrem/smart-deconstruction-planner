local const = require("const")
local lib = require("lib")
local planner_name = "deconstruction-planner"

local stomper_shells = { "small-stomper-shell", "medium-stomper-shell", "big-stomper-shell" }

script.on_event(const.mod_name .. "-hotkey", function(event) create_smart_deconstruction_planner(event) end)

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
        local entity_name
        local entity_type

        -- Handle ghosts vs normal entities.
        if lib.is_ghost(selected) and lib.get_player_setting(player, "ghost-select-underlying") then
            -- Ghosts have their name and type stored in a dedicated field.
            -- Quality is accessed the same for as for non-ghost.
            entity_name = selected.ghost_name
            entity_type = selected.ghost_type
        else
            entity_name = selected.name
            entity_type = selected.type
        end

        if is_tree_or_rock(entity_name, entity_type) then
            stack.trees_and_rocks_only = true
        else
            -- Decide the quality for the filtered entity.
            local quality_mode = lib.get_player_setting(player, "quality-mode")
            local quality
            if quality_mode == "matching-quality" and entity_type ~= "entity-ghost" then
                -- If the entity is an entity ghost, we do not want quality even if the user has it configured.
                -- This is because entity ghosts are too generic for quality to make sense.
                quality = selected.quality
            else
                quality = nil
            end

            entity_name = normalize_rail(entity_name)

            local extended_names = extend_entity_to_group(entity_name)

            for i, name in ipairs(extended_names) do
                stack.set_entity_filter(i, { name = name, quality = quality })
            end

            stack.entity_filter_mode = defines.deconstruction_item.entity_filter_mode.whitelist
        end
    end
end

--[[Normalize the rail to the straight rail prototype.
This way, the created deconstruction planner will work on all rail orientations instead of only that specific orientation.]]
function normalize_rail(entity_name)
    new_entity_name = entity_name
    -- Replace the "half-diagonal-rail", "curved-rail-a" or "curved-rail-b" infix with "straight-rail".
    -- We keep the suffixes intact as to keep the sub-type applicable
    -- (i.e. "elevated-half-diagonal-rail-minimal" becomes "elevated-straight-rail-minimal")
    new_entity_name = new_entity_name:gsub("half%-diagonal%-rail", "straight-rail")
    new_entity_name = new_entity_name:gsub("curved%-rail%-[ab]", "straight-rail")

    if prototypes.entity[new_entity_name] then
        -- As we just created a new name, we have to make sure it actually exists.
        return new_entity_name
    else
        -- As we just created a new name, we have to make sure it actually exists.
        return entity_name
    end
end

function is_stomper_shell(entity_name)
    return lib.table_contains(stomper_shells, entity_name)
end

--[[Check if the entity is a tree or rock. This excludes stomper shells, despite them having the same type as rocks.]]
function is_tree_or_rock(entity_name, entity_type)
    return lib.table_contains({ "tree", "simple-entity" }, entity_type) and not is_stomper_shell(entity_name)
end

--[[Extend an entity to include similar entities.
Currently this just extends elevated rails to also include their supports and ramps.]]
function extend_entity_to_group(entity_name)
    if entity_name:find("elevated%-straight%-rail%-minimal") then
        -- Explicit support for "minimalist-rails" mod, as these define a custom ramp.
        return { entity_name, "rail-ramp-minimal", "rail-support" }
    elseif entity_name:find("elevated%-straight%-rail") then
        -- Vanilla rails.
        return { entity_name, "rail-ramp", "rail-support" }
    elseif is_stomper_shell(entity_name) then
        return stomper_shells
    else
        return { entity_name }
    end
end
