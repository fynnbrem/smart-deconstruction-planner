---@param value any
---@param indent string|nil
---@param visited table|nil
---@return string
local function table_to_string(value, indent, visited)
    indent = indent or ""
    visited = visited or {}

    -- Non-table values
    local t = type(value)
    if t ~= "table" then
        if t == "string" then
            return string.format("%q", value)
        else
            return tostring(value)
        end
    end

    -- Detect cycles
    if visited[value] then
        return "<circular>"
    end
    visited[value] = true

    local next_indent = indent .. "  "
    local parts = { "{" }

    -- Iterate all key/value pairs
    for k, v in pairs(value) do
        local key_repr
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
            key_repr = k
        else
            key_repr = "[" .. table_to_string(k, next_indent, visited) .. "]"
        end

        local value_repr = table_to_string(v, next_indent, visited)

        parts[#parts + 1] = string.format(
            "\n%s%s = %s,", -- comma for readability
            next_indent,
            key_repr,
            value_repr
        )
    end

    parts[#parts + 1] = "\n" .. indent .. "}"
    return table.concat(parts)
end

return table_to_string
