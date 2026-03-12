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

function Util.get_waypoint_text_size(text, font_size)
    local char_width = font_size or 12
    return {
        x = #text * char_width + 10, -- add padding
        y = 20
    }
end

function Util.show_waypoint(player, pos, text, show_distance)
    local waypoint_id = player:hud_add({
        type = "waypoint",
        name = text,
        world_pos = pos,
        text = show_distance and "m" or nil,
        precision = show_distance and 2 or 0,
        number = 0xFFFFFF
    })

    local bg_id = player:hud_add({
        type = "image_waypoint",
        world_pos = pos,
        text = "waypoint_bg.png",
        z_index = -300,
        scale = Util.get_waypoint_text_size(text)
    })

    local removed = false

    local function remove()
        if removed then
            return
        end
        removed = true

        player:hud_remove(waypoint_id)
        player:hud_remove(bg_id)
    end

    return remove
end
