function SCR_Hand_IsHovered(_index, _count, _spacing, _start_x) {
    var _card_w = 73;
    var _card_h = 101;
    var _hover_scale = 1.2; // Match this to whatever scale you use when hovering
    
    var _x = _start_x + (_index * _spacing);
    var _y = hand_Y;
    
    // For hovered card, use scaled dimensions
    var _hovered = false;
    
    // Check if hovering over this card's position
    if (mouse_x >= _x && mouse_x <= _x + (_card_w * _hover_scale) &&
        mouse_y >= _y - 40 && mouse_y <= _y + (_card_h * _hover_scale)) {
        _hovered = true;
    }
    
    // Overlap check - if mouse is past the next card's position,
    // the next card should take priority (right-to-left scanning)
    if (_index < _count - 1) {
        var _next_x = _start_x + ((_index + 1) * _spacing);
        // Use the scaled width for the next card too
        if (mouse_x >= _next_x + (_card_w * (_hover_scale - 1) / 2)) {
            _hovered = false;
        }
    }
    
    return _hovered;
}