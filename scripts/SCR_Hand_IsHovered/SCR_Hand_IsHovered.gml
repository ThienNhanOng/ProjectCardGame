function SCR_Hand_IsHovered(_index, _count, _spacing, _start_x) {
    var _card_w = 73;
    var _card_h = 101;
    
    var _x = _start_x + (_index * _spacing);
    var _y = hand_Y;
    
    var _hovered = (mouse_x >= _x && mouse_x <= _x + _card_w &&
                    mouse_y >= _y - 40 && mouse_y <= _y + _card_h);
    
    if (_index < _count - 1) {
        var _next_x = _start_x + ((_index + 1) * _spacing);
        if (mouse_x >= _next_x) _hovered = false;
    }
    
    return _hovered;
}