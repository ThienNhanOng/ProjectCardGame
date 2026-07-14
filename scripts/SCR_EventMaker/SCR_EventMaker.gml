/// @description Event marker logic — battle events on the world map

enum EVENT_TYPE {
    DIALOG,
    BATTLE,
    ROOM_TRANSITION
}

function eventmarker_init() {
    marker_event_type = EVENT_TYPE.BATTLE;
    event_id    = 0;
    dialog_text = "...";
    battle_room = Room_battle;
    enemy_type  = noone;
    target_room = noone;
    target_x    = 0;
    target_y    = 0;
    target_spawn_event_id = -1;
    marker_goto_immediate = false;
    interact_hint = "Press E";

    // Room Editor instance variables (clone marker, then edit in Instance Variables)
    if (!variable_instance_exists(id, "marker_order")) marker_order = 0;
    if (!variable_instance_exists(id, "marker_label")) marker_label = "";
    if (!variable_instance_exists(id, "marker_battle")) marker_battle = "";
    if (!variable_instance_exists(id, "marker_battleset")) marker_battleset = "";
    if (!variable_instance_exists(id, "marker_replay_pool")) marker_replay_pool = "";

    marker_reward_gift_count = 0;
    marker_reward_randomize = true;
    marker_reward_entries = [];

    marker_dialog_pre = undefined;
    marker_dialog_post = undefined;
    marker_dialog_pre_once = true;
    marker_dialog_post_once = true;

    depth = -10;
    sprite_index = Map_Marker_inactive;
    image_blend = c_white;
    image_alpha = 1;
}

/// @desc Set marker battle config — call in each map marker object's Create event (after event_inherited())
/// @param _order       Unlock order in the map chain (1 = first event, 2 = second, …)
/// @param _label       Name shown on the map when the marker is active
/// @param _battle      Battle id for the **first** clear (must exist in the battleset JSON)
/// @param _battleset   Battleset filename, e.g. "Grasslands_Battleset01_starter.json"
/// @param _replay_pool Comma-separated battle ids for **replays** after first clear, e.g. "battle01,battle02"
function eventmarker_apply_config(_order, _label, _battle, _battleset, _replay_pool) {
    marker_order = _order;
    marker_label = _label;
    marker_battle = _battle;
    marker_battleset = _battleset;
    marker_replay_pool = _replay_pool;
}

/// @desc Configure card rewards on **first clear only** (not replays)
/// @param _gift_count  How many cards to grant (number of picks from the reward set)
/// @param _randomize   true = weighted roll each pick | false = walk entries in order
/// @param _rewardset   Optional preset — array of { id, chance [, collection] } or string "id:chance,..."
function eventmarker_apply_reward(_gift_count, _randomize, _rewardset = undefined) {
    marker_reward_gift_count = max(0, floor(_gift_count));
    marker_reward_randomize = _randomize;
    marker_reward_entries = (_rewardset == undefined)
        ? []
        : eventmarker_NormalizeRewardSet(_rewardset);
}

/// @desc Add one card line to the reward set (call after eventmarker_apply_reward)
/// @param _card_id     Card id from card_DB
/// @param _chance      Weight / percent-style chance (20 = 20% when entries sum to 100)
/// @param _collection  Optional JSON collection name when ids overlap across files
/// @param _once        true = can only be obtained once ever from rewards (removed from pool after)
function eventmarker_reward_add(_card_id, _chance, _collection = "", _once = false) {
    if (!is_array(marker_reward_entries)) marker_reward_entries = [];
    array_push(marker_reward_entries, {
        id: max(0, floor(_card_id)),
        chance: max(0, real(_chance)),
        collection: string(_collection),
        once: _once
    });
}

/// @desc Dialog script to play before battle starts (function returning entry array)
function eventmarker_set_dialog_pre(_script_func) {
    marker_dialog_pre = _script_func;
}

/// @desc Dialog script to play after returning to map from this marker's battle
function eventmarker_set_dialog_post(_script_func) {
    marker_dialog_post = _script_func;
}

/// @desc When true, pre-battle dialog only plays before the event is first cleared
function eventmarker_set_dialog_pre_once(_once = true) {
    marker_dialog_pre_once = _once;
}

/// @desc When true, post-battle dialog only plays after the event is first cleared
function eventmarker_set_dialog_post_once(_once = true) {
    marker_dialog_post_once = _once;
}

/// @desc After winning this marker's battle, send the player to another room (first clear only)
/// @param _room Room asset or name string, e.g. "Room_Worldmap2"
/// @param _spawn_event_id Optional event id on the destination map (-1 = default room spawn)
/// @param _immediate true = skip battle and transition on interact (pre-dialog still plays if set)
function eventmarker_set_room_goto(_room, _spawn_event_id = -1, _immediate = false) {
    target_room = room_Goto_ResolveRoom(_room);
    target_spawn_event_id = floor(_spawn_event_id);
    marker_goto_immediate = _immediate;

    if (_immediate || marker_battle == "") {
        marker_event_type = EVENT_TYPE.ROOM_TRANSITION;
    } else {
        marker_event_type = EVENT_TYPE.BATTLE;
    }
}

function eventmarker_NormalizeRewardEntry(_raw) {
    if (!is_struct(_raw)) return { id: 0, chance: 0, collection: "", once: false };

    var _id = variable_struct_exists(_raw, "id") ? floor(_raw.id) : 0;
    var _chance = 100;
    if (variable_struct_exists(_raw, "chance")) _chance = real(_raw.chance);
    else if (variable_struct_exists(_raw, "weight")) _chance = real(_raw.weight);

    var _collection = "";
    if (variable_struct_exists(_raw, "collection")) _collection = string(_raw.collection);
    else if (variable_struct_exists(_raw, "cardset")) _collection = string(_raw.cardset);

    var _once = false;
    if (variable_struct_exists(_raw, "once")) _once = _raw.once;
    else if (variable_struct_exists(_raw, "one_time")) _once = _raw.one_time;

    return { id: _id, chance: max(0, _chance), collection: _collection, once: _once };
}

function eventmarker_ParseRewardEntryToken(_token) {
    var _trimmed = string_trim(_token);
    if (_trimmed == "") return eventmarker_NormalizeRewardEntry(undefined);

    var _parts = string_split(_trimmed, ":");
    var _id = floor(real(string_trim(_parts[0])));
    var _chance = (array_length(_parts) > 1) ? real(string_trim(_parts[1])) : 100;
    var _collection = (array_length(_parts) > 2) ? string_trim(_parts[2]) : "";

    var _once = false;
    if (array_length(_parts) > 3) {
        var _flag = string_lower(string_trim(_parts[3]));
        _once = (_flag == "once" || _flag == "1" || _flag == "true");
    }

    return { id: _id, chance: max(0, _chance), collection: _collection, once: _once };
}

function eventmarker_NormalizeRewardSet(_rewardset) {
    var _entries = [];

    if (is_array(_rewardset)) {
        for (var i = 0; i < array_length(_rewardset); i++) {
            var _entry = eventmarker_NormalizeRewardEntry(_rewardset[i]);
            if (_entry.id > 0 && _entry.chance > 0) array_push(_entries, _entry);
        }
        return _entries;
    }

    if (is_string(_rewardset) && _rewardset != "") {
        var _parts = string_split(_rewardset, ",");
        for (var s = 0; s < array_length(_parts); s++) {
            var _entry = eventmarker_ParseRewardEntryToken(_parts[s]);
            if (_entry.id > 0 && _entry.chance > 0) array_push(_entries, _entry);
        }
    }

    return _entries;
}

function eventmarker_CopyRewardEntries(_entries) {
    var _copy = [];
    if (!is_array(_entries)) return _copy;
    for (var i = 0; i < array_length(_entries); i++) {
        array_push(_copy, eventmarker_NormalizeRewardEntry(_entries[i]));
    }
    return _copy;
}

function eventmarker_refresh_visual() {
    if (event_id <= 0) {
        sprite_index = Map_Marker_inactive;
        image_blend = c_white;
        image_alpha = 0.55;
        return;
    }

    var _state = worldmap_GetEventState(event_id);

    switch (_state) {
        case WORLDMAP_EVENT_STATE.LOCKED:
            sprite_index = Map_Marker_inactive;
            image_blend = c_white;
            image_alpha = 0.55;
            break;
        case WORLDMAP_EVENT_STATE.AVAILABLE:
            sprite_index = Map_Marker_orange;
            image_blend = c_white;
            image_alpha = 1;
            break;
        case WORLDMAP_EVENT_STATE.CLEARED:
            sprite_index = Map_marker_Active;
            image_blend = c_white;
            image_alpha = 1;
            break;
    }
}

function eventmarker_get_label() {
    var _def = worldmap_GetEventDef(event_id);
    if (_def != undefined && _def.label != "") return _def.label;
    return "Event " + string(event_id);
}

function eventmarker_is_player_near() {
    var _player = instance_find(OBJ_PlayerMarker, 0);
    if (_player == noone) return false;
    return point_distance(x, y, _player.x, _player.y) <= WORLDMAP_INTERACT_RADIUS;
}

function eventmarker_check_interact() {
    if (dialog_IsActive()) return;
    if (!worldmap_CanInteractEvent(event_id)) return;
    if (!eventmarker_is_player_near()) return;
    if (!keyboard_check_pressed(ord("E"))) return;
    eventmarker_trigger();
}

function eventmarker_trigger() {
    switch (marker_event_type) {
        case EVENT_TYPE.DIALOG:
            eventmarker_do_dialog();
            break;
        case EVENT_TYPE.BATTLE:
            eventmarker_do_battle();
            break;
        case EVENT_TYPE.ROOM_TRANSITION:
            eventmarker_do_transition();
            break;
    }
}

function eventmarker_do_dialog() {
    if (marker_dialog_pre != undefined) {
        var _skip = marker_dialog_pre_once && worldmap_IsEventCleared(event_id);
        if (!_skip) {
            dialog_Start(marker_dialog_pre);
            return;
        }
    }
}

function eventmarker_do_battle() {
    eventmarker_BeginBattleFlow();
}

function eventmarker_BeginBattleFlow() {
    if (event_id <= 0) {
return;
    }

    dialog_Init();
    global.dialog.launch_event_id = event_id;
    global.dialog.launch_dialog_post = marker_dialog_post;
    global.dialog.launch_dialog_post_once = marker_dialog_post_once;

    var _skip_pre = marker_dialog_pre_once && worldmap_IsEventCleared(event_id);
    if (marker_dialog_pre != undefined && !_skip_pre) {
        dialog_Start(marker_dialog_pre, eventmarker_LaunchBattleAfterDialog);
        return;
    }

    eventmarker_LaunchBattleAfterDialog();
}

function eventmarker_LaunchBattleAfterDialog() {
    dialog_Init();

    var _event_id = global.dialog.launch_event_id;
    var _dialog_post = global.dialog.launch_dialog_post;
    var _dialog_post_once = true;
    if (variable_struct_exists(global.dialog, "launch_dialog_post_once")) {
        _dialog_post_once = global.dialog.launch_dialog_post_once;
    }

    dialog_ForceClose();

    if (_dialog_post != undefined) {
        var _skip_post = _dialog_post_once && worldmap_IsEventCleared(_event_id);
        if (!_skip_post) {
            worldmap_InitGlobals();
            global.worldmap.pending_dialog_post = _dialog_post;
        }
    }

    global.dialog.launch_event_id = -1;
    global.dialog.launch_dialog_post = undefined;
    global.dialog.launch_dialog_post_once = true;

    if (_event_id > 0) {
        worldmap_LaunchEventBattle(_event_id);
    }
}

function eventmarker_do_transition() {
    if (target_room == -1 || !room_exists(target_room)) return;

    var _skip_pre = marker_dialog_pre_once && worldmap_IsEventCleared(event_id);
    if (marker_dialog_pre != undefined && !_skip_pre) {
        dialog_Start(marker_dialog_pre, eventmarker_DoTransitionAfterDialog);
        return;
    }

    eventmarker_DoTransitionAfterDialog();
}

function eventmarker_DoTransitionAfterDialog() {
    dialog_ForceClose();

    if (target_room == -1 || !room_exists(target_room)) return;

    worldmap_InitGlobals();

    if (target_spawn_event_id > 0) {
        global.worldmap.pending_spawn_event_id = target_spawn_event_id;
    } else if (target_x != 0 || target_y != 0) {
        global.spawn_x = target_x;
        global.spawn_y = target_y;
    }

    room_goto(target_room);
}

function eventmarker_draw_overlay() {
    if (!worldmap_CanInteractEvent(event_id)) return;

    var _label = eventmarker_get_label();
    var _near = eventmarker_is_player_near();

    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text(x, y - 4, _label);

    if (_near) {
        draw_set_valign(fa_top);
        draw_set_color(c_yellow);
        draw_text(x, y + sprite_height * 0.5 + 8, interact_hint);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
