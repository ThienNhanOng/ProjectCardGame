/// @desc Room transition helpers — room_Goto("Room_Worldmap2") or room_Goto(Room_Worldmap2)

function room_Goto_ResolveRoom(_room) {
    if (is_real(_room) && room_exists(_room)) return _room;

    if (is_string(_room)) {
        var _idx = asset_get_index(_room);
        if (_idx != -1 && room_exists(_idx)) return _idx;
    }

    return -1;
}

/// @param _room Room asset or name string, e.g. "Room_Worldmap2"
function room_Goto(_room) {
    var _target = room_Goto_ResolveRoom(_room);
    if (_target == -1) return false;

    room_goto(_target);
    return true;
}

/// @param _room Room asset or name string
/// @param _event_id World-map event marker to snap the player to on arrival
function room_GotoEvent(_room, _event_id = 1) {
    worldmap_InitGlobals();
    global.worldmap.pending_spawn_event_id = max(1, floor(_event_id));
    return room_Goto(_room);
}
