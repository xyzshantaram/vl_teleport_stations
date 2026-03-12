VlTeleport = VlTeleport or {}

function VlTeleport.get_station_place_formspec()
    local formspec = {
        "formspec_version[10]",
        "size[6.375,3]",
        "allow_close[false]",
        "field[0.375,0.75;5.625,0.8;station_name;Station name;]",
        "button_exit[0.4,1.8;2.6,0.8;station_place_cancelled;Cancel]",
        "button_exit[3.375,1.8;2.6,0.8;station_place;Place]"
    }

    return table.concat(formspec, "")
end

local function get_station_list()
    local stations = VlTeleport.get_stations()
    local names = {}

    for name, pos in pairs(stations) do
        if pos ~= nil then
            table.insert(names, core.formspec_escape(name))
        end
    end

    table.sort(names)
    return table.concat(names, ",")
end

function VlTeleport.get_station_use_formspec()
    local station_list = get_station_list()
    local formspec = {
        "formspec_version[10]",
        "size[6.375,3.375]",
        "allow_close[false]",
        "button_exit[0.4,2.2;2.6,0.8;station_go_cancelled;Cancel]",
        "button_exit[3.375,2.2;2.6,0.8;station_go;Go]",
        "dropdown[0.375,1.1;5.625,0.8;station_name;" .. station_list .. ";1;false]",
        "label[0.375,0.7;Where do you want to go?]"
    }

    return table.concat(formspec, "")
end
