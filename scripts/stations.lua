VlTeleport = VlTeleport or {}
VlTeleport.storage = VlTeleport.storage or core.get_mod_storage()

---Return the list of stations.
---@return table a map of stations to positions.
function VlTeleport.get_stations()
    local stations = VlTeleport.storage:get_string("stations")
    if not stations then
        VlTeleport.storage:set_string("stations", core.serialize({}))
    end

    return core.deserialize(stations) or {}
end

---Set station at pos.
---@param name string The name of the station.
---@param pos table|nil The x,y,z pos of the station. Can be nil to delete a station.
function VlTeleport.set_station(name, pos)
    local stations = VlTeleport.get_stations()
    stations[name] = pos
    VlTeleport.storage:set_string("stations", core.serialize(stations))
end

---Get a station by its name. Returns nil if station doesn't exist
---@param name string
---@return table|nil
function VlTeleport.get_station(name)
    local stations = VlTeleport.get_stations()
    return stations[name]
end
