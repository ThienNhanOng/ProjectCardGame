/// @description Draw a single extra deck card - matches collection card style exactly
function SCR_ExtraDeck_DrawCard(_x, _y, _w, _h, _card_data) {
    // Get hover transform from imported function
    var _transform = SCR_DeckHover_GetTransform(_x, _y, _w, _h);
    
    // Draw glow effect
    SCR_DeckHover_DrawGlow(_transform.draw_x, _transform.draw_y, _transform.w, _transform.h, _transform.is_hovered);
    
    var _draw_x = _transform.draw_x;
    var _draw_y = _transform.draw_y;
    var _draw_scale = _transform.draw_scale;
    var _scaled_w = _transform.w;
    var _scaled_h = _transform.h;
    
    // Background
    draw_set_color(c_white);
    draw_rectangle(_draw_x, _draw_y, _draw_x + _scaled_w, _draw_y + _scaled_h, false);
    draw_set_color(c_black);
    draw_rectangle(_draw_x, _draw_y, _draw_x + _scaled_w, _draw_y + _scaled_h, true);
    
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
        var _area_w = _scaled_w - 8;
        var _area_h = _scaled_h - 52;
        var _scale = min(_area_w / _spr_w, _area_h / _spr_h);
        
        var _draw_x_pos = _draw_x + _scaled_w / 2;
        var _draw_y_pos = _draw_y + 30 + _area_h / 2;
        
        draw_sprite_ext(_spr, 0, _draw_x_pos, _draw_y_pos, _scale, _scale, 0, c_white, 1);
    }
    
    // Name
    draw_set_color(c_blue);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(_draw_x + _scaled_w / 2, _draw_y + 3, _card_data.name);
    
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
    draw_text(_draw_x + _scaled_w / 2, _draw_y + 16, _type_text);
    
    // Level - matches SCR_CardSlot_DrawLevel exactly
    if (variable_struct_exists(_card_data, "level")) {
        draw_set_color(c_green);
        draw_set_halign(fa_left);
        draw_set_valign(fa_bottom);
        draw_text(_draw_x + 26, _draw_y + _scaled_h - 0, "Lv " + string(_card_data.level));
    }
    
    // Owned count badge - matches SCR_CardSlot_DrawCountBadge exactly
    if (variable_struct_exists(_card_data, "owned") && _card_data.owned > 0) {
        draw_set_color(c_lime);
        draw_circle(_draw_x + _scaled_w - 12, _draw_y + 12, 10, false);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(_draw_x + _scaled_w - 12, _draw_y + 12, string(_card_data.owned));
    }
    
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}