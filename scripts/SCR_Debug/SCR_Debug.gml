/// @desc Optional debug overlays and console logging (all disabled by default).
/// Enable macros below, or copy snippets from reference/DEBUG_ARCHIVE.gml

#macro DEBUG_LOG_ENABLED false
#macro DEBUG_DRAW_WORLDMAP_INFO false
#macro DEBUG_DRAW_BATTLE_STATUS false
#macro DEBUG_DRAW_MOUSE_XY true
#macro DEBUG_DRAW_WORLDMAP_XY false
#macro DEBUG_DRAW_HAND_COUNT false
#macro DEBUG_DRAW_ENEMY_HITBOXES false

function debug_Log(_msg) {
    if (!DEBUG_LOG_ENABLED) return;
    show_debug_message(_msg);
}

function debug_DrawWorldMapInfo(_gw, _gh) {
    if (!DEBUG_DRAW_WORLDMAP_INFO) return;

    worldmap_InitGlobals();
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(12, _gh - 72, "Map: " + global.worldmap.map_id);
    draw_text(12, _gh - 56, "Progress: " + string(array_length(global.worldmap.cleared))
        + " / " + string(array_length(global.worldmap.event_flow)));
    draw_text(12, _gh - 40, "WASD move | E interact at active markers");
}

function debug_DrawWorldMapCoordinates() {
    if (!DEBUG_DRAW_WORLDMAP_XY) return;

    var _player = instance_find(OBJ_PlayerMarker, 0);
    var _px = (_player != noone) ? floor(_player.x) : -1;
    var _py = (_player != noone) ? floor(_player.y) : -1;

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text(12, 8, "Player: " + string(_px) + ", " + string(_py));
    draw_text(12, 24, "Mouse: " + string(floor(mouse_x)) + ", " + string(floor(mouse_y)));
    draw_set_color(c_white);
}

/// Field = living enemies on board. DB = monster database entry count.
function debug_DrawBattleStatus(_monster_manager_id) {
    if (!DEBUG_DRAW_BATTLE_STATUS) return;

    with (_monster_manager_id) {
        var _board = instance_find(OBJ_BoardManager, 0);
        var _living = (_board != noone) ? monster_CountLivingActive(_board) : 0;
        var _db_count = (variable_global_exists("monster_DB") && is_struct(global.monster_DB))
            ? array_length(global.monster_DB.enemies) : 0;

        draw_set_color(c_yellow);
        draw_text(10, 10, "Queue: " + string(monster_GetQueueCount())
            + " | Slots: " + string(active_slot_count)
            + " | Field: " + string(_living)
            + " | DB: " + string(_db_count));

        if (variable_instance_exists(id, "battle_name")) {
            draw_text(10, 26, "Battle: " + battle_name);
        }

        if (battle_won) {
            draw_set_color(c_lime);
            draw_text(10, 42, "Victory!");
        }

        draw_set_color(c_white);
    }
}

function debug_DrawMouseCoordinates() {
    if (!DEBUG_DRAW_MOUSE_XY) return;

    var _text = "X: " + string(floor(mouse_x)) + "  Y: " + string(floor(mouse_y));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_black);
    draw_text(9, 9, _text);
    draw_set_color(c_yellow);
    draw_text(8, 8, _text);
    draw_set_color(c_white);
}

function debug_DrawHandCount(_hand_count) {
    if (!DEBUG_DRAW_HAND_COUNT) return;

    draw_set_color(c_white);
    draw_text(10, 10, "Hand Count: " + string(_hand_count));
}

function debug_DrawEnemyHoverOverlay(_monster_manager_id) {
    if (!DEBUG_DRAW_ENEMY_HITBOXES) return;

    with (_monster_manager_id) {
        SCR_Monster_DrawHoverDebug();
    }
}
