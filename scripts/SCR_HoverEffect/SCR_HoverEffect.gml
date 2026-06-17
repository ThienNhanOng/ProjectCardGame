function SCR_DeckHover_GetTransform(_x, _y, _w, _h) {
    var _mx = mouse_x;
    var _my = mouse_y;
    var _is_hovered = (_mx >= _x && _mx <= _x + _w &&
                       _my >= _y && _my <= _y + _h);
    
    var _draw_x = _x;
    var _draw_y = _y;
    var _draw_scale = 1.0;
    
    if (_is_hovered) {
        _draw_x = _x - 4;
        _draw_y = _y - 8;
        _draw_scale = 1.05;
    }
    
    return {
        draw_x: _draw_x,
        draw_y: _draw_y,
        draw_scale: _draw_scale,
        is_hovered: _is_hovered,
        w: _w * _draw_scale,
        h: _h * _draw_scale
    };
}

function SCR_DeckHover_DrawGlow(_draw_x, _draw_y, _w, _h, _is_hovered) {
    if (!_is_hovered) return;
    
    // Glow effect
    draw_set_color(c_yellow);
    draw_set_alpha(0.15);
    draw_rectangle(_draw_x - 8, _draw_y - 8, _draw_x + _w + 8, _draw_y + _h + 8, false);
    draw_set_alpha(1);
    
    // Border
    draw_set_color(c_yellow);
    draw_set_alpha(0.5);
    draw_rectangle(_draw_x - 3, _draw_y - 3, _draw_x + _w + 3, _draw_y + _h + 3, true);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// @description Check if mouse is hovering over a card
/// @param {real} _x - Card X position
/// @param {real} _y - Card Y position
/// @param {real} _w - Card width
/// @param {real} _h - Card height
/// @returns {bool} - True if hovered

function SCR_DeckHover_IsHovered(_x, _y, _w, _h) {
    var _mx = mouse_x;
    var _my = mouse_y;
    return (_mx >= _x && _mx <= _x + _w &&
            _my >= _y && _my <= _y + _h);
}