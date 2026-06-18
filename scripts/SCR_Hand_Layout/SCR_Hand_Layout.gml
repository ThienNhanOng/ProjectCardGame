/// @desc Shared hand layout — draw, hover, and click use the same bounds

function SCR_Hand_GetMetrics() {
    return {
        card_w: 73,
        card_h: 101,
        hover_scale: 1.3,
        hover_lift: 30,
        center_x: 600 / 2 + 35
    };
}

/// hand_Y is the resting sprite center (matches legacy draw position)
function SCR_Hand_GetAnchorY(_hand_y) {
    return _hand_y - SCR_Hand_GetMetrics().card_h / 2;
}

function SCR_Hand_GetStartX(_count, _spacing) {
    var _m = SCR_Hand_GetMetrics();
    if (_count <= 0) return _m.center_x;
    var _total = (_spacing * (_count - 1)) + _m.card_w;
    return _m.center_x - (_total / 2);
}

function SCR_Hand_GetCardHitbox(_index, _count, _spacing, _hand_y, _start_x, _expanded) {
    var _m = SCR_Hand_GetMetrics();
    var _left = _start_x + (_index * _spacing);
    var _scale = _expanded ? _m.hover_scale : 1;
    var _base_y = SCR_Hand_GetAnchorY(_hand_y);
    var _top = _base_y - (_expanded ? _m.hover_lift : 0);

    var _cx = _left + _m.card_w / 2;
    var _cy = _top + _m.card_h / 2;
    var _half_w = (_m.card_w / 2) * _scale;
    var _half_h = (_m.card_h / 2) * _scale;

    return {
        left: _cx - _half_w,
        top: _cy - _half_h,
        right: _cx + _half_w,
        bottom: _cy + _half_h,
        center_x: _cx,
        center_y: _cy,
        scale: _scale
    };
}

function SCR_Hand_GetCardSlotHitbox(_index, _count, _spacing, _hand_y, _start_x) {
    var _m = SCR_Hand_GetMetrics();
    var _left = _start_x + (_index * _spacing);
    var _right = (_index < _count - 1)
        ? _start_x + ((_index + 1) * _spacing)
        : _left + _m.card_w;
    var _top = SCR_Hand_GetAnchorY(_hand_y);

    return {
        left: _left,
        top: _top,
        right: _right,
        bottom: _top + _m.card_h
    };
}

function SCR_Hand_PointInHitbox(_mx, _my, _box) {
    return (_mx >= _box.left && _mx < _box.right &&
            _my >= _box.top && _my <= _box.bottom);
}

function SCR_Hand_GetBaseHoveredIndex(_mx, _my, _count, _spacing, _hand_y) {
    if (_count <= 0) return -1;

    var _start_x = SCR_Hand_GetStartX(_count, _spacing);
    for (var i = _count - 1; i >= 0; i--) {
        var _slot = SCR_Hand_GetCardSlotHitbox(i, _count, _spacing, _hand_y, _start_x);
        if (SCR_Hand_PointInHitbox(_mx, _my, _slot)) return i;
    }
    return -1;
}

function SCR_Hand_PickCardIndex(_mx, _my, _count, _spacing, _hand_y) {
    if (_count <= 0) return -1;

    var _start_x = SCR_Hand_GetStartX(_count, _spacing);
    var _hovered = SCR_Hand_GetBaseHoveredIndex(_mx, _my, _count, _spacing, _hand_y);

    for (var i = _count - 1; i >= 0; i--) {
        var _box = SCR_Hand_GetCardHitbox(i, _count, _spacing, _hand_y, _start_x, i == _hovered);
        if (SCR_Hand_PointInHitbox(_mx, _my, _box)) return i;
    }
    return -1;
}

function SCR_Hand_TruncateName(_name, _max_width) {
    if (string_width(_name) <= _max_width) return _name;

    var _short = _name;
    while (string_length(_short) > 1 && string_width(_short + "...") > _max_width) {
        _short = string_copy(_short, 1, string_length(_short) - 1);
    }
    return _short + "...";
}

function SCR_Hand_GetCardNameLabel(_name, _box, _hovered) {
    var _pad = 6;
    var _max_w = (_box.right - _box.left) - _pad * 2;
    if (_hovered) return _name;
    return SCR_Hand_TruncateName(_name, _max_w);
}
