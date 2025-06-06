local rail_types = {
  "straight-rail",
  "half-diagonal-rail",
  "curved-rail-a",
  "curved-rail-b",
  "elevated-half-diagonal-rail",
  "elevated-curved-rail-a",
  "elevated-curved-rail-b"
}

function contains(item, array)
  for _, compare in pairs(array) do
    if item == compare then
      return true
    end
  end
  return false
end

--#region
-- We want to ensure that any stale train indicators get removed.
-- This happens especially when the user exits the game while a train indicator is active.
local function clear_on_first_tick(event)
  rendering.clear("personal-trains")
  script.on_event(defines.events.on_tick, nil)
end

script.on_load(function()
  script.on_event(defines.events.on_tick, clear_on_first_tick)
end)
--#endregion


--#region
-- Register the Shortcut and Hotkey handlers.
script.on_event("personal-trains-call-hotkey", function(event) call_train(event) end)

script.on_event("personal-trains-schedule-hotkey", function(event) open_train_schedule(event) end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "personal-trains-call-shortcut" then
    call_train(event)
  end
  if event.prototype_name == "personal-trains-schedule-shortcut" then
    open_train_schedule(event)
  end
end
)
--#endregion

function get_personal_train(player)
  for _, train in pairs(game.train_manager.get_trains { surface = player.surface, force = player.force }) do
    if train_matches_player(train, player) then
      return train
    end
  end
end

function open_train_schedule(event)
  local player = game.players[event.player_index]
  local personal_train = get_personal_train(player)
  if personal_train == nil then
    show_no_train(player)
    return
  end
  player.opened = personal_train.locomotives.front_movers[1]
end

--[[All trains which are actively being called. The key is the train ID and the value is a callback to be called when the call is finished or overwritten. Do not set this manually, instead use `register_active_call()`.]]
active_calls = {}

function call_train(event)
  local player = game.players[event.player_index]
  local player_selected = player.selected
  local selected_rail
  -- First check if the player has a specific rail selected, and only if not, use the nearest rail instead.
  if player_selected ~= nil and contains(player_selected.type, rail_types) then
    selected_rail = player.selected
  else
    selected_rail = get_nearest_rail(player)
  end
  if selected_rail == nil then
    show_no_rail(player)
    return
  end

  local called_train_id = nil
  local selected_train = get_personal_train(player)


  if selected_train ~= nil then
    local record = {}
    record.temporary = true
    record.rail = selected_rail
    record.wait_conditions = {
      { compare_type = "or",  type = "inactivity",       ticks = 60 * 15 },
      { compare_type = "or",  type = "inactivity",       ticks = 60 * 5 },
      { compare_type = "and", type = "passenger_present" },
    }

    -- Insert the record into the train schedule.
    -- If the train has no schedule yet, create one from the new record.
    if selected_train.schedule ~= nil then
      schedule = selected_train.schedule

      -- Remove the temporary train station at the first position.
      -- If it exists, it was most likely created by a previous, unfinished train call.
      if (schedule.records[1].temporary == true) then
        table.remove(schedule.records, 1)
      end
      table.insert(schedule.records, 1, record)
      schedule.current = 1
      selected_train.schedule = schedule
    else
      selected_train.schedule = {
        current = 1,
        records = { record }
      }
    end

    selected_train.go_to_station(1)
    called_train_id = selected_train.id

    if selected_train.locomotives.front_movers[1] then
      player.create_local_flying_text { text = "[img=personal-trains-call-icon]", position = selected_train.locomotives.front_movers[1].position }
    end
    if selected_train.locomotives.back_movers[1] then
      player.create_local_flying_text { text = "[img=personal-trains-call-icon]", position = selected_train.locomotives.back_movers[#selected_train.locomotives.back_movers].position }
    end

    -- When the train is already it the target stop, its initialy state will be "arrive_station".
    -- In this case, we do not need to add the waiting indicator.
    if selected_train.state == defines.train_state.arrive_station then
      return
    end
    local renders = highlight_target_rail(selected_rail, player)
    register_active_call(called_train_id, renders)
    script.on_event(defines.events.on_train_changed_state, get_train_arrived_handler(called_train_id, renders))
    script.on_event(defines.events.on_train_schedule_changed, get_schedule_change_handler(called_train_id, renders))
  else
    show_no_train(player)
  end
end

--[[Registers the active call for the train and cleans up any previous call of the train.]]
function register_active_call(train_id, renders)
  local active_call = active_calls[train_id]
  if active_call ~= nil then
    active_call()
  end
  local function cleanup()
    cleanup_train_call(renders)
    active_calls[train_id] = nil
  end
  active_calls[train_id] = cleanup
end

--[[Unregisters the activel call and cleans up any active call of the train.]]
function unregister_active_call(train_id)
  local active_call = active_calls[train_id]
  if active_call ~= nil then
    active_call()
  end
end

--[[Provides visual feedback to the player that no train was found.]]
function show_no_train(player)
  player.create_local_flying_text { text = "[virtual-signal=signal-no-entry][item=locomotive]", position = player.position }
end

--[[Provides visual feedback to the player that no rail was found.]]
function show_no_rail(player)
  player.create_local_flying_text { text = "[virtual-signal=signal-no-entry][item=rail]", position = player.position }
end

function get_schedule_change_handler(required_train)
  return function(event)
    if event.train.id ~= required_train then return end
    unregister_active_call(required_train)
  end
end

function get_train_arrived_handler(required_train)
  return function(event)
    if event.train.id ~= required_train then return end
    if event.train.state == defines.train_state.wait_station or event.train.state == defines.train_state.manual_control then
      unregister_active_call(required_train)
    end
  end
end

function cleanup_train_call(renders)
  for _, render_obj in pairs(renders) do
    render_obj.destroy()
  end
  script.on_event(defines.events.on_train_changed_state, nil)
  script.on_event(defines.events.on_train_schedule_changed, nil)
end

--[[ Draws some graphics to highlight the rail the requested train is headed towards.
Returns the `LuaRenderObjects` created for this.
]]
function highlight_target_rail(rail, player)
  local surface = rail.surface
  local players = { player }
  -- Set a maximum duration of 5 minutes.
  -- This is just a failsafe in case the renders do not get deleted programatically.
  local max_duration = 18000
  -- Draw shadow first.
  local shadow = rendering.draw_circle {
    color = { r = 0, g = 0, b = 0, a = 0.2 },
    radius = 1,
    width = 10,
    filled = false,
    draw_on_ground = true,
    target = rail,
    surface = surface,
    players = players,
    time_to_live = max_duration
  }
  -- Draw main highlight.
  local circle = rendering.draw_circle {
    color = { r = 0.9, g = 0.9, b = 0.9, a = 0.7 },
    radius = 1,
    width = 5,
    filled = false,
    draw_on_ground = true,
    target = rail,
    surface = surface,
    players = players,
    time_to_live = max_duration
  }

  -- Draw the auxiliary symbols.
  local text = rendering.draw_text {
    text = "[img=personal-trains-call-icon]",
    color = { r = 1, g = 1, b = 1 },
    use_rich_text = true,
    scale = 2,
    target = rail,
    surface = surface,
    players = players,
    time_to_live = max_duration
  }

  -- Return IDs for later cleanup.
  return { shadow, circle, text }
end

function train_matches_player(train, player)
  for _, movers in pairs(train.locomotives) do
    for _, locomotive in pairs(movers) do
      if locomotive.color then
        if colors_match(player.color, locomotive.color) then
          return true
        end
      end
    end
  end
  return false
end

--[[Compare the colors ignoring their alpha value.]]
function colors_match(color1, color2)
  return color1.r == color2.r and color1.g == color2.g and color1.b == color2.b
end

function get_nearest_rail(player)
  local radius = 50
  local nearby_rails = player.surface.find_entities_filtered { position = player.character.position, radius = radius, type = rail_types, force = player.force }
  if #nearby_rails == 0 then
    return nil
  end

  return player.surface.get_closest(player.character.position, nearby_rails)
end

local tintable_types = {
  ["locomotive"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
  ["train-stop"] = true,
}

commands.add_command(
  "player-colorize",
  "Apply your player color to the entity you're hovering over",
  function(cmd)
    -- Get the player who ran the command
    local player = game.get_player(cmd.player_index)
    if not player then
      return
    end

    -- Find the entity under the cursor
    local ent = player.selected
    if not ent then
      player.print("No entity under your cursor.")
      return
    end

    if not tintable_types[ent.type] then
      player.print("Cannot dye that entity.")
      return
    end

    if not ent.force == player.force then
      player.print("That entity does not belong to you.")
      return
    end


    -- Apply the player’s color (r,g,b,a) to the entity
    ent.color = player.color
    ent.copy_color_from_train_stop = false
    player.print("Applied your player color to the hovered entity.")
  end
)
