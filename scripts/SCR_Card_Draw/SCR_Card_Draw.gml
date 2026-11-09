/// @desc Draw player cards inside metallic borders (73x101 outer size unchanged)
///
/// Cards show one still frame of their art (CARD_ART_STILL_FRAME); set CARD_ART_ANIMATED to play it instead.
/// Cultivated cards (cardRarity >= 1)
/// get a few gold stars shooting out from the art.

#macro CARD_ART_FPS 10
#macro CARD_ART_ANIMATED false   // cards show a still image; true = play the art's animation
#macro CARD_ART_STILL_FRAME 2     // the frame used for the still image
#macro CARD_STAR_COUNT 5
#macro CARD_STAR_PERIOD 1500   // ms for one star to fly out and fade

function card_GetBorderSprite(_card_or_type) {
    var _type = "";
    if (is_string(_card_or_type)) {
        _type = _card_or_type;
    } else if (_card_or_type != undefined && variable_struct_exists(_card_or_type, "type")) {
        _type = _card_or_type.type;
    }

    switch (_type) {
        case "action": return SPR_CardBorder_Action;
        case "weapon": return SPR_CardBorder_Weapon;
        case "spirit": return SPR_CardBorder_Spirit;
        case "special_monster": return SPR_CardBorder_Spirit;
        default: return SPR_CardBorder_Monster;
    }
}

function card_GetArtSprite(_card) {
    if (_card == undefined) return SPR_Monsterplaceholder;
    if (variable_struct_exists(_card, "base_attack")) return SCR_Monster_GetSprite(_card);   // enemy: its icon
    return SCR_Hand_GetSprite(_card);
}

function card_GetFrameInsets(_w, _h) {
    return {
        left: _w * 0.030,
        right: _w * 0.030,
        top: _h * 0.037,
        bottom: _h * 0.04
    };
}

function card_DrawFramedInRect(_x, _y, _w, _h, _card, _alpha = 1) {
    if (_card == undefined) return;

    var _border = card_GetBorderSprite(_card);
    var _art = card_GetArtSprite(_card);
    var _cx = _x + _w / 2;
    var _cy = _y + _h / 2;

    var _bw = sprite_get_width(_border);
    var _bh = sprite_get_height(_border);
    draw_sprite_ext(_border, 0, _cx, _cy, _w / _bw, _h / _bh, 0, c_white, _alpha);

    var _insets = card_GetFrameInsets(_w, _h);
    var _inner_w = _w - _insets.left - _insets.right;
    var _inner_h = _h - _insets.top - _insets.bottom;
    var _inner_cx = _x + _insets.left + _inner_w / 2;
    var _inner_cy = _y + _insets.top + _inner_h / 2;

    var _aw = sprite_get_width(_art);
    var _ah = sprite_get_height(_art);
    var _art_scale = min(_inner_w / _aw, _inner_h / _ah);
    // art is drawn centred; sprites with a non-centre origin are shifted to match
    var _ax = _inner_cx - (_aw / 2 - sprite_get_xoffset(_art)) * _art_scale;
    var _ay = _inner_cy - (_ah / 2 - sprite_get_yoffset(_art)) * _art_scale;
    draw_sprite_ext(_art, card_GetArtFrame(_card, _art), _ax, _ay, _art_scale, _art_scale, 0, c_white, _alpha);

    if (card_GetRarity(_card) >= 1) card_DrawCultivatedStars(_inner_cx, _inner_cy, _inner_w, _inner_h, _card, _alpha);
}

/// The character a played card stands on the field as (JSON "field_sprite"), or -1 to show the card
function card_GetFieldSprite(_card) {
    if (_card == undefined || !variable_struct_exists(_card, "field_sprite") || !is_string(_card.field_sprite)) return -1;
    if (_card.field_sprite == "" || asset_get_type(_card.field_sprite) != asset_sprite) return -1;
    return asset_get_index(_card.field_sprite);
}

/// Animated art: each card id starts at a different frame so a hand doesn't move in lockstep
function card_GetArtFrame(_card, _art) {
    var _n = sprite_get_number(_art);
    if (_n <= 1) return 0;
    if (!CARD_ART_ANIMATED) return min(CARD_ART_STILL_FRAME, _n - 1);
    var _offset = variable_struct_exists(_card, "id") ? real(_card.id) * 3 : 0;
    return floor(current_time / 1000 * CARD_ART_FPS + _offset) mod _n;
}

/// A few gold stars shooting out from the middle of the art, fading as they go
function card_DrawCultivatedStars(_cx, _cy, _w, _h, _card, _alpha) {
    var _seed = variable_struct_exists(_card, "id") ? real(_card.id) * 977 : 0;
    var _reach = min(_w, _h) * 0.62;
    var _scale = min(_w, _h) / 140;
    gpu_set_blendmode(bm_add);
    for (var i = 0; i < CARD_STAR_COUNT; i++) {
        var _t = current_time + _seed + i * (CARD_STAR_PERIOD / CARD_STAR_COUNT);
        var _cycle = floor(_t / CARD_STAR_PERIOD);
        var _u = (_t mod CARD_STAR_PERIOD) / CARD_STAR_PERIOD;
        var _ang = (i * 137 + _cycle * 71 + _seed) mod 360;
        var _dist = _reach * (0.15 + 0.85 * (1 - power(1 - _u, 2)));
        var _x = _cx + lengthdir_x(_dist, _ang);
        var _y = _cy + lengthdir_y(_dist, _ang) * (_h / _w) * 0.8;
        var _a = sin(_u * pi) * _alpha;
        var _s = _scale * (0.6 + 0.6 * sin(_u * pi));
        draw_sprite_ext(SPR_FX_Star, 0, _x, _y, _s, _s, _u * 200, make_color_rgb(255, 206, 90), _a);
    }
    gpu_set_blendmode(bm_normal);
}

function card_DrawFramedAtCenter(_cx, _cy, _scale, _card, _alpha = 1) {
    var _m = SCR_Hand_GetMetrics();
    var _w = _m.card_w * _scale;
    var _h = _m.card_h * _scale;
    card_DrawFramedInRect(_cx - _w / 2, _cy - _h / 2, _w, _h, _card, _alpha);
}
