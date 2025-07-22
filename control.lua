local const = require("const")
local lib = require("lib")
local deconstruction_planner = "deconstruction-planner"

local stomper_shells = { "small-stomper-shell", "medium-stomper-shell", "big-stomper-shell", "behemoth-stomper-shell" }

script.on_event(const.mod_name .. "-hotkey", function(event) create_smart_deconstruction_planner(event) end)



--[[Check if the entity has any open item requests.
This will check both the direct requests for ghosts and the proxy requests for non-ghosts.]]
local function has_item_request(entity)
    local proxy = nil
    if entity.type == "entity-ghost" then
        proxy = entity
    else
        proxy = entity.item_request_proxy
    end
    if proxy == nil then return false end

    return next(proxy.item_requests) ~= nil
end

--[[Checks if the item stack is a valid deconstruction planner.]]
local function is_stack_valid_deconstruction_planner(stack)
    return lib.is_valid(stack) and stack.valid_for_read and stack.name == deconstruction_planner
end

function create_smart_deconstruction_planner(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end

    -- If the player does not hold a deconstruction planner yet, create one in their hand.
    -- Otherwise, we just extend the existing one.


    -- Create a new planner or manage an existing one.
    cursor_has_planner = is_stack_valid_deconstruction_planner(player.cursor_stack)
    cursor_is_temporary = player.cursor_stack_temporary

    if not cursor_has_planner then
        -- If the player is holding to planner, create a new one.
        player.clear_cursor()
        player.cursor_stack.set_stack { name = deconstruction_planner, count = 1 }
        player.cursor_stack_temporary = true
    elseif not cursor_is_temporary then
        -- If the player is holding a permanent planner, create a new one with the filters copied.
        -- This is so we can extend permanent planners but do not pollute the permananent planner itself.
        local preset_filters = player.cursor_stack.entity_filters
        local preset_trees_and_rocks_only = player.cursor_stack.trees_and_rocks_only
        player.clear_cursor()
        player.cursor_stack.set_stack { name = deconstruction_planner, count = 1 }
        player.cursor_stack_temporary = true

        -- Apply th e settings to the new filter.
        -- We also include "Trees/rocks only" for completeness,
        -- even though currently there is now way to extend such planner.
        player.cursor_stack.entity_filters = preset_filters
        player.cursor_stack.trees_and_rocks_only = preset_trees_and_rocks_only
    end
    -- Do nothing if the player is already holding a temporary planner.


    local stack = player.cursor_stack
    if lib.is_invalid(stack) or not stack.valid_for_read then return end

    local selected = player.selected
    -- If there is an entity selected, set this as the filter. Otherwise, just create an empty deconstruction planner.
    if selected and selected.valid then
        local entity_name
        local entity_type
        local allow_quality = true


        --[[
        Handle the different types of name extraction for certain types. We operate in the following order:
            1. Check if the entity has an item request, in which case we filter just for this type.
                - We do this before ghosts for two reasons:
                    1. It is likely that the user pastes a blueprint and then wants to remove the modules that blueprint inferred, rather than the ghosts.
                    2. The smart planner can be used twice to remove the ghosts in sequence.
            2. Check if the entity is a ghost, in which case we filter for the underlying type.
            3. Handle normal entities.
        ]]
        if has_item_request(selected) and lib.get_player_setting(player, "select-item-requests") then
            entity_name = "item-request-proxy"
            entity_type = "item-request-proxy"

            -- Disallow quality for item requests as they cannot have quality.
            allow_quality = false
        elseif lib.is_ghost(selected) and lib.get_player_setting(player, "ghost-select-underlying") then
            -- Ghosts have their name and type stored in a dedicated field.
            -- Quality is accessed the same for as for non-ghost.
            entity_name = selected.ghost_name
            entity_type = selected.ghost_type
        else
            entity_name = selected.name
            entity_type = selected.type

            -- Disallow quality if we create a generic ghost filter.
            allow_quality = entity_type ~= "entity-ghost"
        end

        local is_tree_or_rock_ = is_tree_or_rock(entity_name, entity_type)
        if (is_tree_or_rock_ and #stack.entity_filters > 0) or (not is_tree_or_rock_ and stack.trees_and_rocks_only) then
            -- Do not modify the planner if the player tries to mix an entity planner with a "Trees and rocks only" planner.
            player.print { "smart-deconstruction-planner.cannot-mix-entities-with-trees" }
        elseif is_tree_or_rock_ then
            stack.trees_and_rocks_only = true
        else
            -- Set "Trees and rocks" to false in case the planner that is being extended had it turned on.
            stack.trees_and_rocks_only = false
            -- Decide the quality for the filtered entity.
            local quality_mode = lib.get_player_setting(player, "quality-mode")
            local quality
            if quality_mode == "matching-quality" and allow_quality then
                -- If the entity is an entity ghost, we do not want quality even if the user has it configured.
                -- This is because entity ghosts are too generic for quality to make sense.
                quality = selected.quality
            else
                quality = nil
            end

            entity_name = normalize_rail(entity_name)

            local extended_names = extend_entity_to_group(entity_name)


            for i, name in ipairs(extended_names) do
                local slot = #stack.entity_filters + 1
                if slot <= stack.entity_filter_count then
                    -- This can create duplicate entries, but we leave it to the user to just not to this.
                    -- Also duplicate entries work just like non-duplicates.
                    stack.set_entity_filter(slot, { name = name, quality = quality })
                else
                    player.print { "smart-deconstruction-planner.deconstruction-planner-cannot-insert-more" }
                    break
                end
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
