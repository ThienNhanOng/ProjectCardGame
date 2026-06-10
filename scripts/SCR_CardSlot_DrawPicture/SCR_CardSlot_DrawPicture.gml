function SCR_CardSlot_DrawPicture() {
    var _spr = noone;
    
    if (card_data.type == "monster" || card_data.type == "special_monster") {
        _spr = SPR_Monsterplaceholder;
    } else if (card_data.type == "weapon") {
        _spr = SPR_Weaponplaceholder;
    } else if (card_data.type == "action") {
        _spr = SPR_Actionplaceholder;
    }
    
    if (_spr != noone) {
        var _spr_w = sprite_get_width(_spr);
        var _spr_h = sprite_get_height(_spr);
        var _area_w = card_w - 8;
        var _area_h = card_h - 52;
        var _scale = min(_area_w / _spr_w, _area_h / _spr_h);
        
        var _draw_x = x + card_w/2;
        // Decrease this number to move image HIGHER
        var _draw_y = y + 30 + _area_h/2;  // Changed from 45 to 30
        
        draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _scale, _scale, 0, c_white, 1);
    }
}