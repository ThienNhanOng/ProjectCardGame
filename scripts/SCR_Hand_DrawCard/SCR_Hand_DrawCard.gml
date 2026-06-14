function SCR_Hand_DrawCard(_index, _spacing, _hovered, _offset_y, _start_x) {
    var _card = hand[_index];
    if (_card == undefined) return;
    
    var _x = _start_x + (_index * _spacing);
    var _y = hand_Y + _offset_y;
    var _draw_y = _hovered ? _y - 30 : _y;
    var _scale = _hovered ? 1.3 : 1.0;
    
    var _spr = SCR_Hand_GetSprite(_card);
    
    draw_sprite_ext(_spr, 0, _x, _draw_y, _scale, _scale, 0, c_white, 1);
    
    draw_set_halign(fa_center);
    var _cx = _x + 36;
    
    draw_set_color(c_black);
    draw_text(_cx, _draw_y + 10, _card.name);
    
    if (variable_struct_exists(_card, "level")) {
        draw_set_color(c_yellow);
        draw_text(_cx, _draw_y + 25, "Lv " + string(_card.level));
    }
    
    draw_set_color(c_white);
    var _type = (_card.type == "special_monster") ? "spirit" : _card.type;
    draw_text(_cx, _draw_y + 40, _type);
}