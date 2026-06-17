/// @description Draw a single extra deck card - matches collection card style exactly
function SCR_ExtraDeck_DrawCard(_x, _y, _w, _h, _card_data) {
    // Background
    draw_set_color(c_white);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(c_black);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    
    // Picture
    var _spr = noone;
    if (_card_data.type == "monster" || _card_data.type == "special_monster") {
        _spr = SPR_Monsterplaceholder;
    } else if (_card_data.type == "weapon") {
        _spr = SPR_Weaponplaceholder;
    } else if (_card_data.type == "action") {
        _spr = SPR_Actionplaceholder;
    } else if (_card_data.type == "spirit") {
        _spr = SPR_Monsterplaceholder;
    }
    
    if (_spr != noone) {
        var _spr_w = sprite_get_width(_spr);
        var _spr_h = sprite_get_height(_spr);
        var _area_w = _w - 8;
        var _area_h = _h - 52;
        var _scale = min(_area_w / _spr_w, _area_h / _spr_h);
        
        var _draw_x = _x + _w / 2;
        var _draw_y = _y + 30 + _area_h / 2;
        
        draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _scale, _scale, 0, c_white, 1);
    }
    
    // Name
    draw_set_color(c_blue);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(_x + _w / 2, _y + 3, _card_data.name);
    
    // Type
    var _type_text = _card_data.type;
    switch (_card_data.type) {
        case "monster":         draw_set_color(c_gray);   break;
        case "special_monster": draw_set_color(c_purple); break;
        case "spirit":          draw_set_color(c_purple); _type_text = "spirit"; break;
        case "weapon":          draw_set_color(c_red);    break;
        case "action":          draw_set_color(c_blue);   break;
    }
    draw_set_halign(fa_center);
    draw_text(_x + _w / 2, _y + 16, _type_text);
    
    // Level - matches SCR_CardSlot_DrawLevel exactly
    if (variable_struct_exists(_card_data, "level")) {
        draw_set_color(c_green);
        draw_set_halign(fa_left);
        draw_set_valign(fa_bottom);
        draw_text(_x + 26, _y + _h - 0, "Lv " + string(_card_data.level));
    }
    
    // Owned count badge - matches SCR_CardSlot_DrawCountBadge exactly
    if (variable_struct_exists(_card_data, "owned") && _card_data.owned > 0) {
        draw_set_color(c_lime);
        draw_circle(_x + _w - 12, _y + 12, 10, false);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(_x + _w - 12, _y + 12, string(_card_data.owned));
    }
    
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}