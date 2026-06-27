/// @description Initialize the extra deck strip — horizontal spirit copy carousel
function SCR_ExtraDeck_Init() {
    extra_x       = container_x + container_w + 5;
    extra_y       = container_y;
    extra_card_w  = card_w;
    extra_card_h  = card_h;
    extra_w       = min(320, max(extra_card_w + 24, room_width - extra_x - 300));
    extra_h       = container_h;
    extra_gap     = 8;
    extra_pad_x   = 8;
    extra_pad_y   = max(8, floor((extra_h - extra_card_h) / 2));
    extra_scroll  = 0;
    extra_focus_index = 0;
}

function SCR_ExtraDeck_GetCopyIds() {
    return SCR_DBD_GetSpiritDeckCopyIds();
}

function SCR_ExtraDeck_GetViewInner() {
    return {
        left: extra_x + extra_pad_x,
        top: extra_y + extra_pad_y,
        right: extra_x + extra_w - extra_pad_x,
        bottom: extra_y + extra_h - extra_pad_y
    };
}

function SCR_ExtraDeck_GetContentWidth(_count) {
    if (_count <= 0) return 0;
    return _count * (extra_card_w + extra_gap) - extra_gap;
}

function SCR_ExtraDeck_GetMaxScroll(_count) {
    var _view = SCR_ExtraDeck_GetViewInner();
    var _view_w = _view.right - _view.left;
    return max(0, SCR_ExtraDeck_GetContentWidth(_count) - _view_w);
}

function SCR_ExtraDeck_GetCardBounds(_index, _scroll) {
    var _view = SCR_ExtraDeck_GetViewInner();
    var _x = _view.left + _index * (extra_card_w + extra_gap) - _scroll;
    var _y = _view.top + max(0, floor((_view.bottom - _view.top - extra_card_h) / 2));
    return {
        x: _x,
        y: _y,
        w: extra_card_w,
        h: extra_card_h
    };
}

function SCR_ExtraDeck_ScrollToShowIndex(_index, _scroll, _count) {
    var _bounds = SCR_ExtraDeck_GetCardBounds(_index, _scroll);
    var _view = SCR_ExtraDeck_GetViewInner();
    var _max_scroll = SCR_ExtraDeck_GetMaxScroll(_count);

    if (_bounds.x < _view.left) {
        _scroll = max(0, _scroll - (_view.left - _bounds.x));
    } else if (_bounds.x + extra_card_w > _view.right) {
        _scroll = min(_max_scroll, _scroll + (_bounds.x + extra_card_w - _view.right));
    }
    return clamp(_scroll, 0, _max_scroll);
}

function SCR_ExtraDeck_ClampFocus(_count) {
    if (_count <= 0) {
        extra_focus_index = 0;
        return;
    }
    extra_focus_index = clamp(extra_focus_index, 0, _count - 1);
}

function SCR_ExtraDeck_PickIndexAt(_mx, _my, _scroll, _count) {
    var _view = SCR_ExtraDeck_GetViewInner();
    if (_mx < _view.left || _mx > _view.right || _my < _view.top || _my > _view.bottom) {
        return -1;
    }

    for (var i = 0; i < _count; i++) {
        var _bounds = SCR_ExtraDeck_GetCardBounds(i, _scroll);
        if (_mx >= _bounds.x && _mx <= _bounds.x + _bounds.w
            && _my >= _bounds.y && _my <= _bounds.y + _bounds.h) {
            return i;
        }
    }
    return -1;
}
