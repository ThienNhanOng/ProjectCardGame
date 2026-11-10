/// @desc Battle screen layout: your side on the left, enemies on the right, a fixed bar at the bottom.
///
///   ┌──────────────────────────────── battlefield (background sprite) ───────────────────────────┐
///   │                         sky: prompts                                          battle log    │
///   │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ y = 300: everyone stands below ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
///   │        back front                               1st (summons)  2nd   3rd                    │
///   │              [0]                                    [6]               [1]                    │
///   │         [3]  [1]   (open middle, action card)       [5]        [3]    [0]                    │
///   │         [4]  [2]                                    [7]        [4]    [2]                    │
///   │  ♥ health bar ──────────                                           ◆◆◆◆◆ mana              │
///   ├──────────────────────────────── bottom bar (never moves) ──────────────────────────────────┤
///   │  turn          │              hand              │  deck  extra   [ END TURN ]                │
///   └────────────────────────────────────────────────────────────────────────────────────────────┘
///   (exact spots: battle_LayoutPlayerFeet / battle_LayoutEnemyFeet)
///
/// Your monster slots 0-2 are the front row, 3-4 the back row (closed until openzone opens them).
/// Weapon slot i sits on monster slot i: weapons are dropped on the monster and show as a chip on its card.
/// The battlefield background comes from (first found): the battle's "background" in its battleset JSON,
/// the map JSON's "battle_background", or SPR_BattleBG_GrassPlains.

#macro BATTLE_UI_Y 534               // top of the bottom bar
#macro BATTLE_CARD_W 88              // your monster cards on the field
#macro BATTLE_CARD_H 122
#macro BATTLE_DEFAULT_BACKGROUND "SPR_BattleBG_GrassPlains"

/// Your spots 0-2 are the front row; 3-4 are the back row (closed until openzone opens them)
#macro PLAYER_FRONT_ROW_SLOTS 3

/// Enemy spots (numbers stay the same, only where they stand matters):
///   0-2  third row, furthest back — the wave fills these first
///   3-4  second row — the wave fills these next
///   5-7  first row, nearest you — kept for summons only (hidden until something is summoned there)
#macro ENEMY_WAVE_SLOTS 5
#macro ENEMY_SLOT_COUNT 8

/// Row of a spot counted from the front (0 = the row facing the other side, higher = further back).
/// You: 0-2 -> 0, 3-4 -> 1. Enemies: 5-7 (summons) -> 0, 3-4 -> 1, 0-2 -> 2.
function battle_LayoutRow(_side, _index) {
    if (_side == SIDE_PLAYER) return (_index < PLAYER_FRONT_ROW_SLOTS) ? 0 : 1;
    if (_index >= ENEMY_WAVE_SLOTS) return 0;
    if (_index >= 3) return 1;
    return 2;
}

// ---------------------------------------------------------------------------
// Unit spots. Every unit stands on the grass: feet at y >= 315, so the highest pedestal's top is
// right at y ~300. Lower on screen = nearer; units may overlap and are drawn far to near, with the
// one under the mouse drawn last (unit_GetDepthOrder in scr_card_targeting).
// Rows are straight lines facing the other side; each row stands in the gaps of the row next to it.
// The enemies stand well back, leaving the middle of the field open.
// ---------------------------------------------------------------------------

#macro UNIT_HOVER_SCALE 1.1   // the unit under the mouse is drawn this much bigger, on top of the others

/// Where your unit in spot _index stands (feet)
function battle_LayoutPlayerFeet(_index) {
    switch (_index) {
        case 0: return { x: 440, y: 315 };   // front row
        case 1: return { x: 440, y: 393 };
        case 2: return { x: 440, y: 472 };
        case 3: return { x: 250, y: 354 };   // back row
        case 4: return { x: 250, y: 433 };
    }
    return { x: 440, y: 393 };
}

/// Centre of your card spot (the card's bottom edge is 10px below the feet)
function battle_LayoutPlayerSlotCentre(_index) {
    var _f = battle_LayoutPlayerFeet(_index);
    return { x: _f.x, y: _f.y - (BATTLE_CARD_H / 2 - 10) };
}

/// Where an enemy stands (feet) in each enemy spot. The wave fills spots in number order, so the
/// middle of the back row comes first; a lone enemy stands in its centre.
function battle_LayoutEnemyFeet(_index) {
    switch (_index) {
        case 0: return { x: 1030, y: 390 };   // third row (back): the wave's first 3
        case 1: return { x: 1030, y: 315 };
        case 2: return { x: 1030, y: 465 };
        case 3: return { x: 915, y: 352 };    // second row: the wave's next 2
        case 4: return { x: 915, y: 428 };
        case 5: return { x: 800, y: 390 };    // first row (front): summons only
        case 6: return { x: 800, y: 315 };
        case 7: return { x: 800, y: 465 };
    }
    return { x: 915, y: 390 };
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------

/// Sprite name for this battle's battlefield
function battle_GetBackgroundName() {
    if (variable_global_exists("battle_runtime_config") && is_struct(global.battle_runtime_config)
        && variable_struct_exists(global.battle_runtime_config, "background") && global.battle_runtime_config.background != "") {
        return global.battle_runtime_config.background;
    }
    if (variable_global_exists("worldmap") && is_struct(global.worldmap)
        && variable_struct_exists(global.worldmap, "battle_background") && global.worldmap.battle_background != "") {
        return global.worldmap.battle_background;
    }
    return BATTLE_DEFAULT_BACKGROUND;
}

/// Put the battlefield sprite on the room's "Background" layer
function battle_ApplyBackground() {
    var _spr = asset_get_index(battle_GetBackgroundName());
    if (_spr == -1 || asset_get_type(battle_GetBackgroundName()) != asset_sprite) _spr = asset_get_index(BATTLE_DEFAULT_BACKGROUND);
    var _layer = layer_get_id("Background");
    if (_layer == -1) return;
    var _bg = layer_background_get_id(_layer);
    if (_bg == -1) return;
    layer_background_sprite(_bg, _spr);
    layer_background_stretch(_bg, false);
    // backdrop extras are drawn right after the background layer, under every card and monster
    layer_script_end(_layer, battle_BackdropLayerScript);
}

/// Runs after the Background layer draws (layer scripts fire for every draw event: only use the main Draw)
function battle_BackdropLayerScript() {
    if (event_type == ev_draw && event_number == 0) battle_DrawBackdrop();
}

// ---------------------------------------------------------------------------
// Backdrop (drawn right after the Background layer: under every card, monster and the hand)
// ---------------------------------------------------------------------------

function battle_DrawBackdrop() {
    battle_DrawEnemyPedestals();
    battle_DrawStatusStrip();
    battle_DrawBottomBar();
}

/// Stone pedestal under every enemy spot in use
function battle_DrawEnemyPedestals() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;
    for (var i = 0; i < array_length(_board.enemy_slots); i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible) continue;
        var _f = battle_LayoutEnemyFeet(i);
        var _here = _slot.occupied && _slot.card != undefined;
        // while it runs up to attack, its circle goes with it
        var _o = _here ? battlefx_UnitOffset(_slot.card) : { x: 0, y: 0 };
        battle_DrawPedestal(_f.x + _o.x, _f.y + _o.y, _here ? 1 : 0.5, 1);
    }
}

/// A stone disc that a character stands on (feet at _x, _y)
function battle_DrawPedestal(_x, _y, _alpha, _scale) {
    var _w = 52 * _scale;
    draw_set_alpha(0.35 * _alpha);
    draw_set_color(c_black);
    draw_ellipse(_x - _w - 4, _y - 6, _x + _w + 4, _y + 26 * _scale, false);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(79, 74, 67));
    draw_ellipse(_x - _w, _y - 8 * _scale, _x + _w, _y + 20 * _scale, false);
    draw_set_color(make_color_rgb(169, 163, 151));
    draw_ellipse(_x - _w + 2, _y - 12 * _scale, _x + _w - 2, _y + 12 * _scale, false);
    draw_set_color(make_color_rgb(196, 190, 178));
    draw_ellipse(_x - _w * 0.7, _y - 9 * _scale, _x + _w * 0.58, _y + 3 * _scale, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// Soft dark band behind the health bar (left) and mana (right), just above the bottom bar
function battle_DrawStatusStrip() {
    var _top = BATTLE_UI_Y - 58;
    var _dark = make_color_rgb(18, 14, 11);
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_color(0, _top, _dark, 0);
    draw_vertex_color(room_width, _top, _dark, 0);
    draw_vertex_color(0, BATTLE_UI_Y, _dark, 0.72);
    draw_vertex_color(room_width, BATTLE_UI_Y, _dark, 0.72);
    draw_primitive_end();
}

/// Carved wood bar with a brass rim; the hand, decks and End Turn sit on it
function battle_DrawBottomBar() {
    var _top = BATTLE_UI_Y;
    var _w = room_width;
    var _h = room_height;
    draw_rectangle_color(0, _top, _w, _h, make_color_rgb(46, 35, 26), make_color_rgb(46, 35, 26),
        make_color_rgb(20, 15, 11), make_color_rgb(20, 15, 11), false);
    // wood grain
    draw_set_color(c_white);
    draw_set_alpha(0.025);
    for (var _y = _top + 10; _y < _h; _y += 9) draw_line(0, _y, _w, _y);
    // brass rim + shadow
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(201, 162, 74));
    draw_rectangle(0, _top, _w, _top + 2, false);
    draw_set_alpha(0.5);
    draw_set_color(c_black);
    draw_rectangle(0, _top + 3, _w, _top + 5, false);
    // section dividers: turn | hand | decks + end turn
    draw_set_alpha(0.25);
    draw_set_color(make_color_rgb(201, 162, 74));
    draw_rectangle(210, _top + 16, 211, _h - 16, false);
    draw_rectangle(960, _top + 16, 961, _h - 16, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// Text with a dark outline, for labels drawn over the battlefield art
function battle_DrawOutlinedText(_x, _y, _text, _color) {
    draw_set_color(make_color_rgb(14, 11, 8));
    for (var _dx = -1; _dx <= 1; _dx++) {
        for (var _dy = -1; _dy <= 1; _dy++) {
            if (_dx != 0 || _dy != 0) draw_text(_x + _dx, _y + _dy, _text);
        }
    }
    draw_set_color(_color);
    draw_text(_x, _y, _text);
}
