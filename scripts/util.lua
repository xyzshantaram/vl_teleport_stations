Util = Util or {}

---Check if an array contains a value.
---@param tab table
---@param val string
---@return boolean
function Util.has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end
