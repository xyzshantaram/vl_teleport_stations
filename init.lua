dofile(core.get_modpath(core.get_current_modname()) .. "/scripts/util.lua")
dofile(core.get_modpath(core.get_current_modname()) .. "/scripts/formspecs.lua")

VlTeleport = VlTeleport or {}
VlTeleport.storage = VlTeleport.storage or core.get_mod_storage()
dofile(core.get_modpath(core.get_current_modname()) .. "/scripts/stations.lua")

local _contexts = {}
local function get_context(name)
    local context = _contexts[name] or {}
    _contexts[name] = context
    return context
end

core.register_on_leaveplayer(function(player)
    _contexts[player:get_player_name()] = nil
end)

core.register_craftitem("vl_teleport_stations:teleport_core", {
    description = "Teleport Core",
    -- VoxeLibre specific, displays tooltip
    _tt_help = "Teleport core. Use it on a base station to allow teleporting.",
    inventory_image = "teleport_core.png",
    on_place = function(stack, placer, pointed_thing)
        if placer:is_player() and pointed_thing.type == "node" then
            local player = placer:get_player_name()
            local node = core.get_node(pointed_thing.under)
            if node.name ~= "vl_teleport_stations:teleport_base" then
                return stack
            end

            VlTeleport.on_station_used(player)
        end

        return stack
    end
})

core.register_craft({
    type = "shaped",
    output = "vl_teleport_stations:teleport_core",
    recipe = {
        { "mcl_core:iron_nugget", "mcl_core:iron_nugget",         "", },
        { "mcl_core:iron_nugget", "mesecons_torch:redstoneblock", "mcl_core:iron_nugget", },
        { "",                     "mcl_core:iron_nugget",         "", }
    }
})

core.register_node("vl_teleport_stations:teleport_base", {
    description = "Teleporter Base",
    __tt_help = "Teleporter base station. Place it and use a teleport core on it.",
    tiles = {
        "teleport_station_top.png",
        "teleport_station_bottom.png",
        "teleport_station_front.png",
        "teleport_station_front.png",
        "teleport_station_front.png",
        "teleport_station_front.png"
    },
    groups = { pickaxey = 3 },
    after_place_node = function(pos, placer, _, _)
        -- Make sure to check placer
        if placer and placer:is_player() then
            local meta = core.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
            VlTeleport.on_station_placed(pos, placer:get_player_name())
        end

        if not (placer and placer:is_player()) then
            core.remove_node(pos)
        end
    end,
    on_dig = function(pos, node, digger)
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        local player_name = digger:get_player_name()

        if player_name ~= owner then
            core.chat_send_player(player_name, "Only the owner can break this!")
            return false -- prevent digging
        end

        local name = meta:get_string("name")
        VlTeleport.set_station(name, nil)

        -- Let default digging happen (removes node, drops item, wears tool)
        return core.node_dig(pos, node, digger)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if itemstack:get_name() == "vl_teleport_stations:teleport_core" then
            return
        end

        local meta = core.get_meta(pos)
        local name = meta:get_string("name")
        local waypoint_label = "Teleport Station: " .. name
        local waypoint_pos = vector.add(pos, { x = 0, y = 1, z = 0 })
        local remove = Util.show_waypoint(clicker, waypoint_pos, waypoint_label, false)
        core.after(3, remove)
    end
})

core.register_craft({
    type = "shaped",
    output = "vl_teleport_stations:teleport_base",
    recipe = {
        { "mcl_core:iron_nugget", "mcl_compass:18",               "mcl_core:iron_nugget", },
        { "mcl_core:iron_nugget", "mesecons_torch:redstoneblock", "mcl_core:iron_nugget", },
        { "",                     "mcl_core:iron_nugget",         "", }
    }
})

---Called when a station is placed but before it is saved. Shows the station placed formspec.
---@param name string
function VlTeleport.on_station_placed(pos, name)
    local context = get_context(name)
    context.pos = pos
    core.show_formspec(name, "vl_teleport_stations:station_place", VlTeleport.get_station_place_formspec())
end

function VlTeleport.on_station_used(name)
    core.show_formspec(name, "vl_teleport_stations:station_use", VlTeleport.get_station_use_formspec())
end

---Formspec result handler for station placement.
---@param player string
---@param fields table
function VlTeleport.on_station_place_submit(player, fields)
    local context = get_context(player)

    local player_ref = core.get_player_by_name(player)
    if not player_ref then
        return
    end

    if fields.station_place_cancelled then
        core.remove_node(context.pos)
        local inv = player_ref:get_inventory()
        local stack = ItemStack("vl_teleport_stations:teleport_base 1")
        local leftover = inv:add_item("main", stack)
    end

    if not context.pos or not fields.station_name then
        return
    end

    local meta = core.get_meta(context.pos)
    local existing = VlTeleport.get_station(fields.station_name)

    if existing then
        core.chat_send_player(player, "A station with that name already exists!")
        local node = core.get_node(context.pos)

        if node.name == "vl_teleport_stations:teleport_base" and meta:get_string("owner") == player then
            core.remove_node(context.pos)
            local inv = player_ref:get_inventory()
            local stack = ItemStack("vl_teleport_stations:teleport_base 1")
            local leftover = inv:add_item("main", stack)

            if (leftover:get_count() > 0) then
                core.add_item(context.pos, stack)
            end
        end

        return
    end

    meta:set_string("name", fields.station_name)
    VlTeleport.set_station(fields.station_name, context.pos)
    context.pos = nil
end

function VlTeleport.on_station_use_submit(player, fields)
    if fields.station_go_cancelled or not fields.station_name then
        return
    end

    if not fields.station_go then
        return
    end

    local player_ref = core.get_player_by_name(player)
    if not player_ref then
        return
    end

    local pos = VlTeleport.get_station(fields.station_name)

    if pos then
        player_ref:set_pos(vector.add(pos, { x = 0, y = 1, z = 0 }))
        local inv = player_ref:get_inventory()
        inv:remove_item("main", "vl_teleport_stations:teleport_core 1")
    end
end

---Player fields receive handler.
---@param player string
---@param formname string
---@param fields table
core.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "vl_teleport_stations:station_place" then
        VlTeleport.on_station_place_submit(player, fields)
    end

    if formname == "vl_teleport_stations:station_use" then
        VlTeleport.on_station_use_submit(player, fields)
    end
end)
