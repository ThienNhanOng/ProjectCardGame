function SCR_Board_Draw() {
    // Always draw placed cards first
    SCR_Board_DrawPlacedCards();
    
    // Only show slot visuals while dragging
    if (!is_dragging) return;
    
    // Draw player monster slots - ONLY if dragging a monster or spirit card
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) continue;
        
        // Only show monster slots if dragging a monster OR special_monster
        if (drag_card != undefined && (drag_card.type == "monster" || drag_card.type == "special_monster")) {
            if (drag_card.type == "special_monster") {
                draw_sprite(SPR_SpiritSlot, 0, _slot.x, _slot.y);  // Green spirit slot
            } else {
                draw_sprite(SPR_MonsterSlot, 0, _slot.x, _slot.y); // Monster slot
            }
        }
    }
    
    // Draw player weapon slots - ONLY if dragging a weapon card
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) continue;
        
        // Only show weapon slots if dragging a weapon
        if (drag_card != undefined && drag_card.type == "weapon") {
            draw_sprite(SPR_WeaponSlot, 0, _slot.x, _slot.y);  // Orange slot
        }
    }
    
    // Draw action slot - ONLY if dragging an action card
    if (action_slot.visible && !action_slot.occupied) {
        if (drag_card != undefined && drag_card.type == "action") {
            draw_sprite(SPR_ActionSlot, 0, action_slot.x, action_slot.y);
        }
    }
}

function SCR_Board_InitSlots() {
    var _card_w = 73;
    var _card_h = 101;
    
    // Calculate diagonal progression
    // From (19, 350) to (84, 442) over 3 visible slots
    // Difference: X changes by +65, Y changes by +92 over 3 slots
    var _x_step = 65 / 3;  // ~21.67 per slot
    var _y_step = 92 / 3;  // ~30.67 per slot
    
    // Monster slots - 5 slots total, positioned diagonally
    player_monster_slots = [];
    for (var i = 0; i < 5; i++) {
        // First 3 slots follow the diagonal from (19,350) to (84,442)
        // Slots 3 and 4 continue the diagonal pattern
        var _x = 19 + (i * _x_step);
        var _y = 350 + (i * _y_step);
        
        player_monster_slots[i] = {
            index    : i,
            type     : "monster",
            owner    : "player",
            occupied : false,
            card     : undefined,
            x        : _x,
            y        : _y,
            w        : _card_w,
            h        : _card_h,
            visible  : (i < 3),  // First 3 visible, last 2 locked initially
            locked   : (i >= 3), // Lock slots 3 and 4
            hovered  : false,
            sprite   : SPR_MonsterSlot
        };
    }
    
    // Weapon slots - positioned below monster slots (continue diagonal)
    player_weapon_slots = [];
    for (var i = 0; i < 3; i++) {
        player_weapon_slots[i] = {
            index    : i,
            type     : "weapon",
            owner    : "player",
            occupied : false,
            card     : undefined,
            x        : 19 + (i * _x_step),           // Same X pattern
            y        : 350 + (i * _y_step) + 120,    // Below monster slots (+120 Y)
            w        : _card_w,
            h        : _card_h,
            visible  : true,
            locked   : false,
            hovered  : false,
            sprite   : SPR_WeaponSlot
        };
    }
    
    // Action slot - positioned to the right of monster slots
    action_slot = {
        index    : 0,
        type     : "action",
        owner    : "player",
        occupied : false,
        card     : undefined,
        x        : 84 + 50,  // After the last diagonal monster slot
        y        : 442,       // At the end Y position
        w        : _card_w,
        h        : _card_h,
        visible  : true,
        hovered  : false,
        sprite   : SPR_ActionSlot
    };
    
    show_debug_message("Board slots initialized diagonally from (19,350) to (84,442)");
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
    
    // Draw cards in enemy slots (if you have them)
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