local const = require("const")
local lib = require("lib")
local table_to_string = require("table_to_string")
local deconstruction_planner = "deconstruction-planner"
local stomper_shells = { "small-stomper-shell", "medium-stomper-shell", "big-stomper-shell" }

-- "Behemoth Enemies" compatibility.
if prototypes.entity["behemoth-stomper-shell"] then
    table.insert(stomper_shells, "behemoth-stomper-shell")
end

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

    local is_fresh = false
    if not cursor_has_planner then
        -- If the player is holding to planner, create a new one.
        player.clear_cursor()
        player.cursor_stack.set_stack { name = deconstruction_planner, count = 1 }
        player.cursor_stack_temporary = true
        is_fresh = true
    elseif not cursor_is_temporary then
        -- If the player is holding a permanent planner, create a new one with the filters copied.
        -- This is so we can extend permanent planners but do not pollute the permananent planner itself.
        local preset_filters = player.cursor_stack.entity_filters
        local preset_trees_and_rocks_only = player.cursor_stack.trees_and_rocks_only
        player.clear_cursor()
        player.cursor_stack.set_stack { name = deconstruction_planner, count = 1 }
        player.cursor_stack_temporary = true

        -- Apply the settings to the new filter.
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


            for index, e_name in ipairs(extended_names) do
                -- Try to insert every entity into the filter.
                -- Only give feedback if:
                --  - This is the first entity of the group to prevent spam.
                --  - The planner is not being initialized from this entity
                --      as the feedback is only for "extending" the planner.
                try_insert_filter(
                    stack,
                    e_name,
                    quality,
                    player,
                    index == 1 and not is_fresh)
            end

            stack.entity_filter_mode = defines.deconstruction_item.entity_filter_mode.whitelist
        end
    end
end

---@param stack LuaItemStack
---@param entity_name string
---@param entity_quality LuaQualityPrototype
---@param give_feedback boolean
---Tries to insert the defined entity into the current stack as filter.
---@returns `false` if the filter is full, `true` otherwise (even if the entity was not inserted due to being a duplicate)
function try_insert_filter(stack, entity_name, entity_quality, player, give_feedback)
    local slot = #stack.entity_filters + 1
    if slot <= stack.entity_filter_count then
        if not is_entity_in_filter(stack, entity_name, entity_quality) then
            stack.set_entity_filter(slot, { name = entity_name, quality = entity_quality })

            local text
            if entity_quality then
                text = "+[entity=" .. entity_name .. ",quality=" .. entity_quality.name .. "]"
            else
                text = "+[entity=" .. entity_name .. "]"
            end
            if give_feedback then
                player.create_local_flying_text { text = text, create_at_cursor = true }
            end
        end
        return true
    else
        player.print { "smart-deconstruction-planner.deconstruction-planner-cannot-insert-more" }
        return false
    end
end

---@param stack LuaItemStack
---@param entity_name string
---@param entity_quality LuaQualityPrototype
--- Check if the entity defined by `entity_name [string]` and `entity_quality [LuaQualityPrototype]` already is in the filters of the `stack`.
--- nil-quality in the filter will match with any `entity_quality`.
function is_entity_in_filter(stack, entity_name, entity_quality)
    for i = 1, stack.entity_filter_count do
        entity = stack.get_entity_filter(i)
        if entity ~= nil then
            if entity_name == entity.name then
                if entity.quality == nil then
                    -- This can occur in two cases:
                    -- 1. The filter is generic, in which case it will span any `entity_quality`.
                    -- 2. The entity does not have a quality (e.g. ghosts or item requests), in which case name match is sufficient.
                    return true
                elseif entity_quality ~= nil and entity.quality == entity_quality.name then
                    -- Due to the condition above, an nil-quality entity cannot match this entry.
                    -- So we just need to check for defined qualities.
                    return true
                end
            end
        end
    end
    return false
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
        -- If the new name is malformed, fall back to the input name.
        return entity_name
    end
end

--[[Check if the `entity_name` matches any type of stomper shell]]
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
