local lib = {}

function lib.table_contains(table, item)
    for _, v in ipairs(table) do
        if v == item then
            return true
        end
    end
    return false
end

return lib
