/// @desc World map config — load JSON, define event flow, battles, replay pools

#macro WORLDMAP_INTERACT_RADIUS 56
#macro WORLDMAP_SNAP_OFFSET_Y 40
#macro WORLDMAP_SNAP_BREAK_HOLD 0.25

enum WORLDMAP_EVENT_STATE {
    LOCKED,
    AVAILABLE,
    CLEARED
}

function worldmap_InitGlobals() {
    if (!variable_global_exists("worldmap") || !is_struct(global.worldmap)) {
        global.worldmap = {
            map_id: "",
            config_file: "",
            battleset_file: "",
            event_flow: [],
            events: {},
            cleared: [],
            active_event_id: -1,
            return_room: Room_Worldmap1,
            collection_return_room: noone,
            victory_pending: false,
            last_reward_text: "",
            rewards_obtained: [],
            pending_spawn_event_id: -1
        };
    }

    if (!variable_struct_exists(global.worldmap, "pending_spawn_event_id")) {
        global.worldmap.pending_spawn_event_id = -1;
    }

    if (!variable_struct_exists(global.worldmap, "pending_dialog_post")) {
        global.worldmap.pending_dialog_post = undefined;
    }

    if (!variable_global_exists("battleset_cache")) {
        global.battleset_cache = {};
    }

    if (!variable_global_exists("battle_runtime_config")) {
        global.battle_runtime_config = undefined;
    }

    if (!variable_struct_exists(global.worldmap, "collection_return_room")) {
        global.worldmap.collection_return_room = noone;
    }

    if (!variable_struct_exists(global.worldmap, "rewards_obtained")
        || !is_array(global.worldmap.rewards_obtained)) {
        global.worldmap.rewards_obtained = [];
    }
}

function worldmap_GetEventKey(_event_id) {
    return string(floor(_event_id));
}

function worldmap_EnsureEventEntry(_event_id) {
    worldmap_InitGlobals();

    var _key = worldmap_GetEventKey(_event_id);
    if (!variable_struct_exists(global.worldmap.events, _key)) {
        global.worldmap.events[$ _key] = {
            id: floor(_event_id),
            label: "Event " + _key,
            battle: "",
            battleset_file: "",
            replay_pool: [],
            reward_gift_count: 0,
            reward_randomize: true,
            reward_entries: []
        };
    }
    return global.worldmap.events[$ _key];
}

/// @desc Replace the linear unlock order, e.g. [1, 2, 3, 4, 5]
function worldmap_SetEventFlow(_flow) {
    worldmap_InitGlobals();
    global.worldmap.event_flow = [];

    if (!is_array(_flow)) return;

    for (var i = 0; i < array_length(_flow); i++) {
        array_push(global.worldmap.event_flow, floor(_flow[i]));
    }
}

/// @desc Pin a specific battle id from the battleset to an event (first clear)
function worldmap_SetEventBattle(_event_id, _battle_id) {
    var _entry = worldmap_EnsureEventEntry(_event_id);
    _entry.battle = string(_battle_id);
}

/// @desc Battles picked at random when revisiting a cleared event
function worldmap_SetEventReplayPool(_event_id, _pool) {
    var _entry = worldmap_EnsureEventEntry(_event_id);
    _entry.replay_pool = [];

    if (!is_array(_pool)) return;

    for (var i = 0; i < array_length(_pool); i++) {
        array_push(_entry.replay_pool, string(_pool[i]));
    }
}

function worldmap_LoadMapConfig(_filename) {
    worldmap_InitGlobals();

    if (!file_exists(_filename)) {
        show_debug_message("World map config not found: " + _filename);
        return false;
    }

    var _file = file_text_open_read(_filename);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _data = json_parse(_json_str);
    global.worldmap.config_file = _filename;
    global.worldmap.map_id = variable_struct_exists(_data, "map_id") ? string(_data.map_id) : "map";
    global.worldmap.battleset_file = variable_struct_exists(_data, "battleset") ? string(_data.battleset) : "";
    global.worldmap.events = {};
    global.worldmap.event_flow = [];

    if (variable_struct_exists(_data, "event_flow") && is_array(_data.event_flow)) {
        worldmap_SetEventFlow(_data.event_flow);
    }

    if (variable_struct_exists(_data, "events") && is_array(_data.events)) {
        for (var i = 0; i < array_length(_data.events); i++) {
            var _src = _data.events[i];
            if (!variable_struct_exists(_src, "id")) continue;

            var _id = floor(_src.id);
            var _key = worldmap_GetEventKey(_id);
            var _pool = [];

            if (variable_struct_exists(_src, "replay_pool") && is_array(_src.replay_pool)) {
                for (var p = 0; p < array_length(_src.replay_pool); p++) {
                    array_push(_pool, string(_src.replay_pool[p]));
                }
            }

            var _reward_entries = [];
            var _reward_gift_count = 0;
            var _reward_randomize = true;

            if (variable_struct_exists(_src, "reward_entries") && is_array(_src.reward_entries)) {
                _reward_entries = eventmarker_CopyRewardEntries(_src.reward_entries);
            } else if (variable_struct_exists(_src, "reward_set") && is_string(_src.reward_set)) {
                _reward_entries = eventmarker_NormalizeRewardSet(_src.reward_set);
            }

            if (variable_struct_exists(_src, "reward_gift_count")) {
                _reward_gift_count = max(0, floor(_src.reward_gift_count));
            } else if (variable_struct_exists(_src, "reward_amount")) {
                _reward_gift_count = max(0, floor(_src.reward_amount));
            }

            if (variable_struct_exists(_src, "reward_randomize")) {
                _reward_randomize = _src.reward_randomize;
            }

            if (array_length(_reward_entries) <= 0) {
                var _legacy = worldmap_BuildRewardFromLegacySource(_src);
                if (array_length(_legacy.entries) > 0) {
                    _reward_entries = _legacy.entries;
                    if (_reward_gift_count <= 0) _reward_gift_count = _legacy.gift_count;
                }
            }

            if (array_length(_reward_entries) > 0 && _reward_gift_count <= 0) {
                _reward_gift_count = 1;
            }

            global.worldmap.events[$ _key] = {
                id: _id,
                label: variable_struct_exists(_src, "label") ? string(_src.label) : ("Event " + _key),
                battle: variable_struct_exists(_src, "battle") ? string(_src.battle) : "",
                battleset_file: variable_struct_exists(_src, "battleset") ? string(_src.battleset) : "",
                replay_pool: _pool,
                reward_gift_count: _reward_gift_count,
                reward_randomize: _reward_randomize,
                reward_entries: _reward_entries
            };

            if (array_length(global.worldmap.event_flow) <= 0) {
                array_push(global.worldmap.event_flow, _id);
            }
        }
    }

    show_debug_message("World map loaded: " + global.worldmap.map_id
        + " | Events: " + string(array_length(global.worldmap.event_flow))
        + " | Battleset: " + global.worldmap.battleset_file);
    return true;
}

function worldmap_BuildRewardFromLegacySource(_src) {
    var _gift_count = 0;
    var _randomize = true;
    var _entries = [];
    if (!is_struct(_src)) {
        return { gift_count: 0, randomize: true, entries: [] };
    }

    if (variable_struct_exists(_src, "reward_card_id") && _src.reward_card_id > 0) {
        _gift_count = variable_struct_exists(_src, "reward_amount")
            ? max(1, floor(_src.reward_amount)) : 1;
        array_push(_entries, { id: floor(_src.reward_card_id), chance: 100, collection: "" });
        return { gift_count: _gift_count, randomize: true, entries: _entries };
    }

    var _pool_raw = "";
    if (variable_struct_exists(_src, "reward_pool_ids")) _pool_raw = string(_src.reward_pool_ids);
    else if (variable_struct_exists(_src, "reward_set")) _pool_raw = string(_src.reward_set);

    if (_pool_raw != "") {
        _entries = eventmarker_NormalizeRewardSet(_pool_raw);
        _gift_count = variable_struct_exists(_src, "reward_amount")
            ? max(1, floor(_src.reward_amount)) : 1;
        return { gift_count: _gift_count, randomize: true, entries: _entries };
    }

    if (variable_struct_exists(_src, "reward_pool") && is_array(_src.reward_pool)
        && array_length(_src.reward_pool) > 0) {
        var _equal = 100 / array_length(_src.reward_pool);
        for (var p = 0; p < array_length(_src.reward_pool); p++) {
            array_push(_entries, { id: floor(_src.reward_pool[p]), chance: _equal, collection: "" });
        }
        _gift_count = variable_struct_exists(_src, "reward_amount")
            ? max(1, floor(_src.reward_amount)) : 1;
    }

    return { gift_count: _gift_count, randomize: _randomize, entries: _entries };
}

function worldmap_GetEventDef(_event_id) {
    worldmap_InitGlobals();
    var _key = worldmap_GetEventKey(_event_id);
    if (!variable_struct_exists(global.worldmap.events, _key)) return undefined;
    return global.worldmap.events[$ _key];
}

function worldmap_IsEventCleared(_event_id) {
    worldmap_InitGlobals();
    var _id = floor(_event_id);

    for (var i = 0; i < array_length(global.worldmap.cleared); i++) {
        if (global.worldmap.cleared[i] == _id) return true;
    }
    return false;
}

function worldmap_GetNextUnclearedEventId() {
    worldmap_InitGlobals();

    for (var i = 0; i < array_length(global.worldmap.event_flow); i++) {
        var _id = global.worldmap.event_flow[i];
        if (!worldmap_IsEventCleared(_id)) return _id;
    }
    return -1;
}

function worldmap_GetEventState(_event_id) {
    var _id = floor(_event_id);
    if (worldmap_IsEventCleared(_id)) return WORLDMAP_EVENT_STATE.CLEARED;

    var _next = worldmap_GetNextUnclearedEventId();
    if (_next == _id) return WORLDMAP_EVENT_STATE.AVAILABLE;

    return WORLDMAP_EVENT_STATE.LOCKED;
}

function worldmap_CanInteractEvent(_event_id) {
    var _state = worldmap_GetEventState(_event_id);
    return _state == WORLDMAP_EVENT_STATE.AVAILABLE || _state == WORLDMAP_EVENT_STATE.CLEARED;
}

function worldmap_MarkEventCleared(_event_id) {
    worldmap_InitGlobals();
    var _id = floor(_event_id);
    if (worldmap_IsEventCleared(_id)) return;

    array_push(global.worldmap.cleared, _id);
    show_debug_message("World map event cleared: " + string(_id));
}

function worldmap_ResolveBattleIdForEvent(_event_id) {
    var _def = worldmap_GetEventDef(_event_id);
    if (_def == undefined) return "";

    if (worldmap_IsEventCleared(_event_id)) {
        if (is_array(_def.replay_pool) && array_length(_def.replay_pool) > 0) {
            return _def.replay_pool[irandom(array_length(_def.replay_pool) - 1)];
        }
    }

    return _def.battle;
}

function worldmap_GetEventBattleset(_event_id) {
    var _def = worldmap_GetEventDef(_event_id);
    if (_def != undefined
        && variable_struct_exists(_def, "battleset_file")
        && _def.battleset_file != "") {
        return _def.battleset_file;
    }
    worldmap_InitGlobals();
    return global.worldmap.battleset_file;
}

function worldmap_ParseReplayPoolString(_raw) {
    var _pool = [];
    if (_raw == undefined || string(_raw) == "") return _pool;

    var _parts = string_split(string(_raw), ",");
    for (var i = 0; i < array_length(_parts); i++) {
        var _id = string_trim(_parts[i]);
        if (_id != "") array_push(_pool, _id);
    }
    return _pool;
}

/// @desc Build event_flow + event defs from OBJ_EventMarker instances in the room
function worldmap_SyncMarkersFromRoom() {
    worldmap_InitGlobals();

    var _json_flow = [];
    var _json_defs = [];
    for (var f = 0; f < array_length(global.worldmap.event_flow); f++) {
        array_push(_json_flow, global.worldmap.event_flow[f]);
        array_push(_json_defs, worldmap_GetEventDef(global.worldmap.event_flow[f]));
    }

    var _markers = [];
    with (OBJ_EventMarker) {
        array_push(_markers, id);
    }
    if (array_length(_markers) <= 0) return;

    array_sort(_markers, function(_a, _b) {
        var _order_a = _a.marker_order;
        var _order_b = _b.marker_order;
        if (_order_a > 0 && _order_b > 0 && _order_a != _order_b) {
            return sign(_order_a - _order_b);
        }
        if (_order_a > 0 && _order_b <= 0) return -1;
        if (_order_b > 0 && _order_a <= 0) return 1;
        if (_a.x == _b.x) return _a.y - _b.y;
        return _a.x - _b.x;
    });

    global.worldmap.event_flow = [];
    global.worldmap.events = {};

    for (var i = 0; i < array_length(_markers); i++) {
        var _inst = _markers[i];
        var _event_id = i + 1;
        var _key = worldmap_GetEventKey(_event_id);

        var _json_def = (i < array_length(_json_defs)) ? _json_defs[i] : undefined;

        var _label = _inst.marker_label;
        if (_label == "" && _json_def != undefined) _label = _json_def.label;
        if (_label == "") _label = "Event " + string(_event_id);

        var _battle = _inst.marker_battle;
        if (_battle == "" && _json_def != undefined) _battle = _json_def.battle;
        if (_battle == "") _battle = "battle01";

        var _battleset = _inst.marker_battleset;
        if (_battleset == "" && _json_def != undefined
            && variable_struct_exists(_json_def, "battleset_file")) {
            _battleset = _json_def.battleset_file;
        }
        if (_battleset == "") _battleset = global.worldmap.battleset_file;

        var _replay = worldmap_ParseReplayPoolString(_inst.marker_replay_pool);
        if (array_length(_replay) <= 0 && _json_def != undefined && is_array(_json_def.replay_pool)) {
            _replay = _json_def.replay_pool;
        }
        if (array_length(_replay) <= 0) {
            array_push(_replay, _battle);
        }

        var _reward_gift_count = 0;
        var _reward_randomize = true;
        var _reward_entries = [];

        if (variable_instance_exists(_inst, "marker_reward_gift_count")) {
            _reward_gift_count = max(0, floor(_inst.marker_reward_gift_count));
        }
        if (variable_instance_exists(_inst, "marker_reward_randomize")) {
            _reward_randomize = _inst.marker_reward_randomize;
        }
        if (variable_instance_exists(_inst, "marker_reward_entries")
            && is_array(_inst.marker_reward_entries)) {
            _reward_entries = eventmarker_CopyRewardEntries(_inst.marker_reward_entries);
        }

        if (array_length(_reward_entries) <= 0 && _reward_gift_count <= 0 && _json_def != undefined) {
            var _legacy = worldmap_BuildRewardFromLegacySource(_json_def);
            _reward_entries = _legacy.entries;
            _reward_gift_count = _legacy.gift_count;
            _reward_randomize = _legacy.randomize;
        }

        if (array_length(_reward_entries) > 0 && _reward_gift_count <= 0) {
            _reward_gift_count = 1;
        }

        global.worldmap.events[$ _key] = {
            id: _event_id,
            label: _label,
            battle: _battle,
            battleset_file: _battleset,
            replay_pool: _replay,
            reward_gift_count: _reward_gift_count,
            reward_randomize: _reward_randomize,
            reward_entries: _reward_entries
        };
        array_push(global.worldmap.event_flow, _event_id);

        with (_inst) {
            event_id = _event_id;
            eventmarker_refresh_visual();
        }
    }

    show_debug_message("World map synced " + string(array_length(_markers))
        + " markers from room (use marker_order to set unlock sequence)");
}
