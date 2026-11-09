/// @desc Battle screen layout: your side on the left, enemies on the right, a fixed bar at the bottom.
///
///   ┌──────────────────────────────── battlefield (background sprite) ───────────────────────────┐
///   │  back  front                                                   front    back  (enemies)     │
///   │  [3]   [0]                                                           goblin                 │
///   │        [1]                     preview / prompts                     goblin                 │
///   │  [4]   [2]                                                           goblin                 │
///   │  ♥ health bar ──────────                                           ◆◆◆◆◆ mana              │
///   ├──────────────────────────────── bottom bar (never moves) ──────────────────────────────────┤
///   │  turn          │              hand              │  deck  extra   [ END TURN ]                │
///   └────────────────────────────────────────────────────────────────────────────────────────────┘
///
/// Monster slots 0-2 are the front column, 3-4 the back column (the hidden zones abilities unlock).
/// Weapon slot i sits on monster slot i: weapons are dropped on the monster and show as a chip on its card.
/// The battlefield background comes from (first found): the battle's "background" in its battleset JSON,
/// the map JSON's "battle_background", or SPR_BattleBG_GrassPlains.

#macro BATTLE_UI_Y 534               // top of the bottom bar
#macro BATTLE_CARD_W 88              // your monster cards on the field
#macro BATTLE_CARD_H 122
#macro BATTLE_DEFAULT_BACKGROUND "SPR_BattleBG_GrassPlains"

/// Centre of each of your monster spots
function battle_LayoutPlayerSlotCentre(_index) {
    switch (_index) {
        case 0: return { x: 380, y: 106 };
        case 1: return { x: 380, y: 268 };
        case 2: return { x: 380, y: 430 };
        case 3: return { x: 195, y: 186 };
        case 4: return { x: 195, y: 350 };
    }
    return { x: 380, y: 268 };
}

/// Where an enemy stands (feet) in each enemy spot
function battle_LayoutEnemyFeet(_index) {
    switch (_index) {
        // front column (0, 2) and back column (1), mirroring your side
        case 0: return { x: 890, y: 196 };
        case 1: return { x: 1085, y: 322 };
        case 2: return { x: 890, y: 452 };
    }
    return { x: 890, y: 322 };
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
        battle_DrawPedestal(_f.x, _f.y, (_slot.occupied && _slot.card != undefined) ? 1 : 0.5, 1);
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
