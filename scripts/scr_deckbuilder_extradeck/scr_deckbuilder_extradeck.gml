/// @desc Deck builder extra deck (spirit) panel

/// @description Initialize the extra deck strip - filters spirit cards from collection
function SCR_ExtraDeck_Init() {
    extra_x       = container_x + container_w + 5;
    extra_y       = container_y;
    extra_card_w  = card_w;
    extra_card_h  = card_h;
    extra_w       = card_w + 20;
    extra_h       = container_h;
    extra_gap     = grid_padding_y;
    
    extra_visible_count = floor(extra_h / (extra_card_h + extra_gap));
    
    extra_cards = [];
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (_card.type == "spirit" && _card.owned > 0) {
            array_push(extra_cards, _card);
        }
    }
    
    extra_current_page = 0;
    extra_cards_per_page = extra_visible_count;
    extra_total_pages = ceil(array_length(extra_cards) / extra_cards_per_page);
    if (extra_total_pages < 1) extra_total_pages = 1;
}

/// @description Draw the extra deck container, label, page counter, and visible cards
function SCR_ExtraDeck_Draw() {
    draw_set_color(c_black);
    draw_set_alpha(0.3);
    draw_rectangle(extra_x, extra_y, extra_x + extra_w, extra_y + extra_h, false);
    draw_set_alpha(1);
    
    draw_set_color(c_white);
    draw_rectangle(extra_x, extra_y, extra_x + extra_w, extra_y + extra_h, true);
    
    // Label
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(extra_x, extra_y - 40, "Spirit Owned");
    
    // Get ONLY spirit cards
    extra_cards = SCR_DBD_GetSpiritCards();
    extra_total_pages = ceil(array_length(extra_cards) / extra_cards_per_page);
    if (extra_total_pages < 1) extra_total_pages = 1;
    
    // Page counter - right aligned with the box edge
    draw_set_halign(fa_right);
    draw_text(extra_x + extra_w, extra_y - 20, "Page " + string(extra_current_page + 1) + "/" + string(extra_total_pages));
    draw_set_halign(fa_left);
    
    var _start = extra_current_page * extra_cards_per_page;
    var _end   = min(_start + extra_cards_per_page, array_length(extra_cards));
    
    for (var i = _start; i < _end; i++) {
        var _card_data = extra_cards[i];
        var _row = i - _start;
        var _bounds = SCR_DBD_GetSpiritCardRowBounds(_row);

        SCR_ExtraDeck_DrawCard(_bounds.x, _bounds.y, _bounds.w, _bounds.h, _card_data);
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

/// @description Draw a single extra deck card - matches collection card style exactly
function SCR_ExtraDeck_DrawCard(_x, _y, _w, _h, _card_data, _force_hover = undefined, _keep_in_box = false) {
    var _transform = SCR_DeckHover_GetTransform(_x, _y, _w, _h, _force_hover);

    if (_keep_in_box) {
        _transform.draw_x = _x;
        _transform.draw_y = _y;
        _transform.draw_scale = 1;
        _transform.w = _w;
        _transform.h = _h;
    }
    
    if (!_keep_in_box) {
        SCR_DeckHover_DrawGlow(_transform.draw_x, _transform.draw_y, _transform.w, _transform.h, _transform.is_hovered);
    } else if (_transform.is_hovered) {
        draw_set_color(c_yellow);
        draw_set_alpha(0.85);
        draw_rectangle(_x + 1, _y + 1, _x + _w - 1, _y + _h - 1, true);
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
    
    var _draw_x = _transform.draw_x;
    var _draw_y = _transform.draw_y;
    var _draw_scale = _transform.draw_scale;
    var _scaled_w = _transform.w;
    var _scaled_h = _transform.h;
    
    // Metallic frame with inset paper art
    card_DrawFramedInRect(_draw_x, _draw_y, _scaled_w, _scaled_h, _card_data, 1);
    
    // Name
    var _pad = 4;
    var _name = SCR_Hand_TruncateName(_card_data.name, _scaled_w - _pad * 2);
    draw_set_color(c_blue);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_draw_x + _pad, _draw_y + 3, _name);
    
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
    
    // Rarity label (common/cultivated); spirits show type only
    var _label = card_GetTierLabel(_card_data);
    if (_label != "") {
        draw_set_color(card_GetTierLabelColor(_card_data));
        draw_set_halign(fa_left);
        draw_set_valign(fa_bottom);
        draw_text(_draw_x + 8, _draw_y + _scaled_h, _label);
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

/// @description Handle mouse wheel + keyboard pagination for the extra deck strip
function SCR_ExtraDeck_Step() {
    if (mouse_x >= extra_x && mouse_x <= extra_x + extra_w &&
        mouse_y >= extra_y && mouse_y <= extra_y + extra_h) {
        
        var _new_page = extra_current_page;
        
        if (mouse_wheel_up())   _new_page--;
        if (mouse_wheel_down()) _new_page++;
        
        if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
            _new_page++;
        }
        if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
            _new_page--;
        }
        
        _new_page = clamp(_new_page, 0, extra_total_pages - 1);
        
        if (_new_page != extra_current_page) {
            extra_current_page = _new_page;
        }
    }
}
