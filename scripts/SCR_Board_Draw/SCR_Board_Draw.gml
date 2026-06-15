function SCR_Board_Draw() {
    // Only draw anything if dragging
    if (!is_dragging) {
        SCR_Board_DrawPlacedCards();
        return;
    }
    
    var _col_glow        = make_color_rgb(255, 140, 0);   // bright orange
    var _col_highlight   = make_color_rgb(255, 255, 180); // light yellow
    var _alpha_tint      = 0.15;
    var _glow_size       = 4;
    
    // Highlight player monster slots
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) continue;
        if (_slot.hovered) SCR_Board_DrawSlotHighlight(_slot, _col_glow, _col_highlight, _alpha_tint, _glow_size);
    }
    
    // Highlight player weapon slots
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) continue;
        if (_slot.hovered) SCR_Board_DrawSlotHighlight(_slot, _col_glow, _col_highlight, _alpha_tint, _glow_size);
    }
    
    // Highlight action slot
    if (action_slot.visible && !action_slot.occupied && action_slot.hovered) {
        SCR_Board_DrawSlotHighlight(action_slot, _col_glow, _col_highlight, _alpha_tint, _glow_size);
    }
    
    // Draw placed cards on top of highlights
    SCR_Board_DrawPlacedCards();
}

function SCR_Board_DrawSlotHighlight(_slot, _col_glow, _col_highlight, _alpha_tint, _glow_size) {
    // Orange glow border
    draw_set_color(_col_glow);
    draw_set_alpha(1);
    draw_rectangle(_slot.x - _glow_size, _slot.y - _glow_size,
                   _slot.x + _slot.w + _glow_size, _slot.y + _slot.h + _glow_size, false);
    
    // Light yellow tint inside
    draw_set_color(_col_highlight);
    draw_set_alpha(_alpha_tint);
    draw_rectangle(_slot.x, _slot.y, _slot.x + _slot.w, _slot.y + _slot.h, false);
    
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function SCR_Board_DrawPlacedCards() {
    // Draw cards placed in player monster slots
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr = SCR_Hand_GetSprite(_slot.card);
        draw_sprite(_spr, 0, _slot.x, _slot.y);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(_slot.x + _slot.w / 2, _slot.y + 5, _slot.card.name);
    }
    
    // Draw cards placed in player weapon slots
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr = SCR_Hand_GetSprite(_slot.card);
        draw_sprite(_spr, 0, _slot.x, _slot.y);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(_slot.x + _slot.w / 2, _slot.y + 5, _slot.card.name);
    }
    
    // Draw card in action slot
    if (action_slot.occupied && action_slot.card != undefined) {
        var _spr = SCR_Hand_GetSprite(action_slot.card);
        draw_sprite(_spr, 0, action_slot.x, action_slot.y);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(action_slot.x + action_slot.w / 2, action_slot.y + 5, action_slot.card.name);
    }
    
    // Draw cards in enemy slots
    for (var i = 0; i < array_length(enemy_slots); i++) {
        var _slot = enemy_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr = SCR_Hand_GetSprite(_slot.card);
        draw_sprite(_spr, 0, _slot.x, _slot.y);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(_slot.x + _slot.w / 2, _slot.y + 5, _slot.card.name);
    }
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}