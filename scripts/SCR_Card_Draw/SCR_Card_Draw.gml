/// @desc Draw player cards inside metallic borders (73x101 outer size unchanged)

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
    draw_sprite_ext(_art, 0, _inner_cx, _inner_cy, _art_scale, _art_scale, 0, c_white, _alpha);
}

function card_DrawFramedAtCenter(_cx, _cy, _scale, _card, _alpha = 1) {
    var _m = SCR_Hand_GetMetrics();
    var _w = _m.card_w * _scale;
    var _h = _m.card_h * _scale;
    card_DrawFramedInRect(_cx - _w / 2, _cy - _h / 2, _w, _h, _card, _alpha);
}
