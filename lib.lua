local const = require("const")
local this = {}

function this.table_contains(table, item)
    for _, v in ipairs(table) do
        if v == item then
            return true
        end
    end
    return false
end

function this.is_ghost(entity)
    return entity.type == "entity-ghost"
end

--[[Returns the value of the setting with the `main_key` for the `player`.
The key must only be the main part, the name of the mod will be prefixed automatically.]]
function this.get_player_setting(player, main_key)
    return settings.get_player_settings(player)[const.mod_name .. "-" .. main_key].value
end

function this.is_valid(entity)
    return entity ~= nil and entity.valid
end

function this.is_invalid(entity)
    return entity == nil or not entity.valid
end

return this
