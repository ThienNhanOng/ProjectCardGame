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
    interact_hint = "Press E";

    // Room Editor instance variables (clone marker, then edit in Instance Variables)
    if (!variable_instance_exists(id, "marker_order")) marker_order = 0;
    if (!variable_instance_exists(id, "marker_label")) marker_label = "";
    if (!variable_instance_exists(id, "marker_battle")) marker_battle = "";
    if (!variable_instance_exists(id, "marker_battleset")) marker_battleset = "";
    if (!variable_instance_exists(id, "marker_replay_pool")) marker_replay_pool = "";
}

/// @desc Set marker battle config — edit each Map marker object's Create event
function eventmarker_apply_config(_order, _label, _battle, _battleset, _replay_pool) {
    marker_order = _order;
    marker_label = _label;
    marker_battle = _battle;
    marker_battleset = _battleset;
    marker_replay_pool = _replay_pool;
}

function eventmarker_refresh_visual() {
    var _state = worldmap_GetEventState(event_id);

    switch (_state) {
        case WORLDMAP_EVENT_STATE.LOCKED:
            sprite_index = Map_Marker_inactive;
            image_blend = c_white;
            break;
        case WORLDMAP_EVENT_STATE.AVAILABLE:
            sprite_index = Map_Marker_orange;
            image_blend = c_white;
            break;
        case WORLDMAP_EVENT_STATE.CLEARED:
            sprite_index = Map_marker_Active;
            image_blend = c_lime;
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
    show_debug_message("Dialog: " + dialog_text);
}

function eventmarker_do_battle() {
    if (event_id <= 0) {
        show_debug_message("Event marker missing event_id");
        return;
    }
    worldmap_LaunchEventBattle(event_id);
}

function eventmarker_do_transition() {
    global.spawn_x = target_x;
    global.spawn_y = target_y;
    room_goto(target_room);
}

function eventmarker_draw_overlay() {
    if (!worldmap_CanInteractEvent(event_id)) {
        draw_set_halign(fa_center);
        draw_set_color(c_ltgray);
        draw_text(x, y - 28, "Event " + string(event_id));
        draw_set_halign(fa_left);
        draw_set_color(c_white);
        return;
    }

    var _label = eventmarker_get_label();
    var _state = worldmap_GetEventState(event_id);
    var _near = eventmarker_is_player_near();

    draw_set_halign(fa_center);
    draw_set_color(_state == WORLDMAP_EVENT_STATE.CLEARED ? c_lime : c_white);
    draw_text(x, y - 28, _label);

    if (_near) {
        draw_set_color(c_yellow);
        draw_text(x, y + sprite_height * 0.5 + 8, interact_hint);
        if (marker_battle != "") {
            draw_set_color(c_ltgray);
            draw_text(x, y + sprite_height * 0.5 + 22, marker_battle);
        }
    }

    draw_set_halign(fa_left);
    draw_set_color(c_white);
}
