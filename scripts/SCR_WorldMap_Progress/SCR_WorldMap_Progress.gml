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
    global.worldmap.last_reward_text = "";

    var _event_id = global.worldmap.active_event_id;
    global.worldmap.last_reward_text = worldmap_GrantEventRewards(_event_id);
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
    global.worldmap.last_reward_text = "";
    battle_SyncExtraDeckFromBattleState();
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

    var _msg = "Victory! Press E / Enter / Click to return to map";
    if (variable_struct_exists(global.worldmap, "last_reward_text")
        && global.worldmap.last_reward_text != "") {
        _msg = "Victory! Obtained: " + global.worldmap.last_reward_text
            + " — Press E / Enter / Click to return";
    }

    draw_text(room_width / 2, room_height - 48, _msg);
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

function worldmap_AssignEventMarkers() {
    worldmap_SyncMarkersFromRoom();
}

function worldmap_InitRoom(_config_file = "Grasslands_WorldMap01.json") {
    worldmap_InitGlobals();
    collection_EnsurePlayerInitialized();
    global.worldmap.return_room = room;
    worldmap_LoadMapConfig(_config_file);
    worldmap_SyncMarkersFromRoom();
}

/// @desc Default JSON config per map room (override via room creation code global)
function worldmap_GetRoomConfigFile(_room = room) {
    switch (_room) {
        case Room_Worldmap1: return "Grasslands_WorldMap01.json";
        default: return "Grasslands_WorldMap01.json";
    }
}

function worldmap_GetCollectionButtonBounds() {
    var _w = display_get_gui_width();
    var _h = display_get_gui_height();
    return {
        x1: _w - 150,
        y1: _h - 48,
        x2: _w - 20,
        y2: _h - 12
    };
}

function worldmap_DrawCollectionButton() {
    var _bounds = worldmap_GetCollectionButtonBounds();
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _hover = (_mx >= _bounds.x1 && _mx <= _bounds.x2
        && _my >= _bounds.y1 && _my <= _bounds.y2);

    draw_set_color(_hover ? c_aqua : make_color_rgb(40, 90, 140));
    draw_rectangle(_bounds.x1, _bounds.y1, _bounds.x2, _bounds.y2, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text((_bounds.x1 + _bounds.x2) * 0.5, (_bounds.y1 + _bounds.y2) * 0.5, "Collection");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function worldmap_HandleCollectionButton() {
    if (!mouse_check_button_pressed(mb_left)) return;

    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _bounds = worldmap_GetCollectionButtonBounds();
    if (_mx < _bounds.x1 || _mx > _bounds.x2
        || _my < _bounds.y1 || _my > _bounds.y2) {
        return;
    }

    worldmap_OpenCollection();
}

function worldmap_OpenCollection() {
    worldmap_InitGlobals();
    global.worldmap.collection_return_room = room;
    room_goto(Room_collection);
}

function worldmap_GetCollectionReturnRoom() {
    worldmap_InitGlobals();
    var _dest = global.worldmap.collection_return_room;
    if (_dest == noone) _dest = Room_Worldmap1;
    return _dest;
}

function worldmap_NormalizeRewardEntry(_raw) {
    return eventmarker_NormalizeRewardEntry(_raw);
}

function worldmap_GetRewardTrackKey(_entry) {
    var _norm = worldmap_NormalizeRewardEntry(_entry);
    return string(_norm.id) + "|" + _norm.collection;
}

function worldmap_IsRewardObtained(_entry) {
    worldmap_InitGlobals();
    var _key = worldmap_GetRewardTrackKey(_entry);

    for (var i = 0; i < array_length(global.worldmap.rewards_obtained); i++) {
        if (global.worldmap.rewards_obtained[i] == _key) return true;
    }
    return false;
}

function worldmap_MarkRewardObtained(_entry) {
    worldmap_InitGlobals();
    var _norm = worldmap_NormalizeRewardEntry(_entry);
    if (!_norm.once) return;

    var _key = worldmap_GetRewardTrackKey(_norm);
    if (worldmap_IsRewardObtained(_norm)) return;

    array_push(global.worldmap.rewards_obtained, _key);
    show_debug_message("One-time reward obtained: card id " + string(_norm.id)
        + (_norm.collection != "" ? " (" + _norm.collection + ")" : ""));
}

/// @desc Drop one-time entries already obtained; keep repeatable entries
function worldmap_FilterAvailableRewardEntries(_entries) {
    var _filtered = [];
    if (!is_array(_entries)) return _filtered;

    for (var i = 0; i < array_length(_entries); i++) {
        var _entry = worldmap_NormalizeRewardEntry(_entries[i]);
        if (_entry.id <= 0 || _entry.chance <= 0) continue;
        if (_entry.once && worldmap_IsRewardObtained(_entry)) continue;
        array_push(_filtered, _entry);
    }
    return _filtered;
}

function worldmap_PickWeightedRewardEntry(_entries) {
    if (!is_array(_entries) || array_length(_entries) <= 0) {
        return worldmap_NormalizeRewardEntry(undefined);
    }

    var _total = 0;
    for (var i = 0; i < array_length(_entries); i++) {
        var _entry = worldmap_NormalizeRewardEntry(_entries[i]);
        _total += _entry.chance;
    }
    if (_total <= 0) return worldmap_NormalizeRewardEntry(undefined);

    var _roll = random(_total);
    var _acc = 0;
    for (var j = 0; j < array_length(_entries); j++) {
        var _pick = worldmap_NormalizeRewardEntry(_entries[j]);
        _acc += _pick.chance;
        if (_roll < _acc) return _pick;
    }

    return worldmap_NormalizeRewardEntry(_entries[array_length(_entries) - 1]);
}

function worldmap_PickRewardEntry(_entries, _randomize, _pick_index) {
    if (!is_array(_entries) || array_length(_entries) <= 0) {
        return worldmap_NormalizeRewardEntry(undefined);
    }

    if (!_randomize) {
        var _slot = _pick_index mod array_length(_entries);
        return worldmap_NormalizeRewardEntry(_entries[_slot]);
    }

    return worldmap_PickWeightedRewardEntry(_entries);
}

function worldmap_JoinRewardTexts(_texts) {
    var _txt = "";
    for (var i = 0; i < array_length(_texts); i++) {
        if (_texts[i] == "") continue;
        if (_txt != "") _txt += ", ";
        _txt += _texts[i];
    }
    return _txt;
}

function worldmap_GrantEventRewards(_event_id) {
    var _def = worldmap_GetEventDef(_event_id);
    if (_def == undefined) return "";

    var _gift_count = variable_struct_exists(_def, "reward_gift_count")
        ? max(0, floor(_def.reward_gift_count)) : 0;
    var _all_entries = variable_struct_exists(_def, "reward_entries") && is_array(_def.reward_entries)
        ? _def.reward_entries : [];
    var _randomize = !variable_struct_exists(_def, "reward_randomize") || _def.reward_randomize;

    if (_gift_count <= 0 || array_length(_all_entries) <= 0) return "";

    var _granted = [];
    for (var g = 0; g < _gift_count; g++) {
        var _pool = worldmap_FilterAvailableRewardEntries(_all_entries);
        if (array_length(_pool) <= 0) break;

        var _pick = worldmap_PickRewardEntry(_pool, _randomize, g);
        if (_pick.id <= 0) continue;

        if (collection_GrantBattleReward(_pick.id, 1, _pick.collection)) {
            array_push(_granted, collection_FormatRewardText(_pick.id, 1));
            worldmap_MarkRewardObtained(_pick);
        }
    }

    return worldmap_JoinRewardTexts(_granted);
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
