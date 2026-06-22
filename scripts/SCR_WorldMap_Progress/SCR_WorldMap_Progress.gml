/// @desc World map runtime — launch battles, sync markers, return after victory

/// @desc Launch any battle id directly (future hooks, debug, scripted fights)
function worldmap_StartBattle(_battle_id, _battleset_file = "") {
    worldmap_InitGlobals();

    if (_battleset_file == "") {
        _battleset_file = global.worldmap.battleset_file;
    }
    if (_battleset_file == "") {
        show_debug_message("worldmap_StartBattle: no battleset file set");
        return false;
    }

    var _config = battle_GetBattlesetBattle(_battleset_file, _battle_id);
    if (_config == undefined) return false;

    global.battle_runtime_config = _config;
    global.worldmap.active_event_id = -1;
    global.worldmap.victory_pending = false;
    room_goto(Room_battle);
    return true;
}

function worldmap_LaunchEventBattle(_event_id) {
    worldmap_InitGlobals();

    if (!worldmap_CanInteractEvent(_event_id)) {
        show_debug_message("Event " + string(_event_id) + " is locked");
        return false;
    }

    var _battle_id = worldmap_ResolveBattleIdForEvent(_event_id);
    if (_battle_id == "") {
        show_debug_message("Event " + string(_event_id) + " has no battle configured");
        return false;
    }

    var _config = battle_GetBattlesetBattle(worldmap_GetEventBattleset(_event_id), _battle_id);
    if (_config == undefined) return false;

    var _def = worldmap_GetEventDef(_event_id);
    var _label = (_def != undefined) ? _def.label : ("Event " + string(_event_id));

    global.battle_runtime_config = _config;
    global.worldmap.active_event_id = floor(_event_id);
    global.worldmap.victory_pending = false;
    global.worldmap.return_room = room;

    show_debug_message("Launching " + _label + " -> " + _battle_id);
    room_goto(Room_battle);
    return true;
}

function worldmap_NotifyBattleVictory() {
    worldmap_InitGlobals();
    if (global.worldmap.active_event_id <= 0) return;
    global.worldmap.victory_pending = true;
}

function worldmap_ReturnToMapAfterVictory() {
    worldmap_InitGlobals();

    if (global.worldmap.active_event_id > 0) {
        worldmap_MarkEventCleared(global.worldmap.active_event_id);
    }

    var _return_room = global.worldmap.return_room;
    if (_return_room == noone) _return_room = Room_Worldmap1;

    global.worldmap.active_event_id = -1;
    global.worldmap.victory_pending = false;
    battle_EndSession();

    room_goto(_return_room);
}

function worldmap_BattleVictoryStep() {
    worldmap_InitGlobals();
    if (!global.worldmap.victory_pending) return;

    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_mm == noone || !_mm.battle_won) return;

    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("E"))
        || mouse_check_button_pressed(mb_left)) {
        worldmap_ReturnToMapAfterVictory();
    }
}

function worldmap_DrawBattleVictoryPrompt() {
    worldmap_InitGlobals();
    if (!global.worldmap.victory_pending) return;

    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_mm == noone || !_mm.battle_won) return;

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_lime);
    draw_text(room_width / 2, room_height - 48, "Victory! Press E / Enter / Click to return to map");
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

function worldmap_AssignEventMarkers() {
    worldmap_SyncMarkersFromRoom();
}

function worldmap_InitRoom(_config_file = "Grasslands_WorldMap01.json") {
    worldmap_InitGlobals();
    worldmap_LoadMapConfig(_config_file);
    worldmap_SyncMarkersFromRoom();
}

function worldmap_RefreshAllMarkers() {
    with (OBJ_EventMarker) {
        eventmarker_refresh_visual();
    }
}

function worldmap_GetNearestInteractableEvent(_player_inst) {
    if (_player_inst == noone) return noone;

    var _best = noone;
    var _best_dist = WORLDMAP_INTERACT_RADIUS + 1;

    with (OBJ_EventMarker) {
        if (!worldmap_CanInteractEvent(event_id)) continue;
        var _dist = point_distance(_player_inst.x, _player_inst.y, x, y);
        if (_dist <= WORLDMAP_INTERACT_RADIUS && _dist < _best_dist) {
            _best = id;
            _best_dist = _dist;
        }
    }

    return _best;
}

function worldmap_TryPlayerInteract(_player_inst) {
    var _marker = worldmap_GetNearestInteractableEvent(_player_inst);
    if (_marker == noone) return false;

    with (_marker) {
        eventmarker_trigger();
    }
    return true;
}
