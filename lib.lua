local const = require("const")
local lib = {}

function lib.table_contains(table, item)
    for _, v in ipairs(table) do
        if v == item then
            return true
        end
    end
    return false
end

function lib.is_ghost(entity)
    return entity.type == "entity-ghost"
end

--[[Returns the value of the setting with the `main_key` for the `player`.
The key must only be the main part, the name of the mod will be prefixed automatically.]]
function lib.get_player_setting(player, main_key)
    return settings.get_player_settings(player)[const.mod_name .. "-" .. main_key].value
end

return lib
