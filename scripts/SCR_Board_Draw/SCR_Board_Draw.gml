function SCR_Board_Draw() {
    SCR_Board_DrawPlacedCards();
    
    if (!is_dragging) return;
    
    var _card_w = 73;
    var _card_h = 101;
    
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) continue;
        if (drag_card != undefined && (drag_card.type == "monster" || drag_card.type == "special_monster")) {
            if (drag_card.type == "special_monster") {
                draw_sprite(SPR_SpiritSlot, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2);
            } else {
                draw_sprite(SPR_MonsterSlot, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2);
            }
        }
    }
    
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) continue;
        if (drag_card != undefined && drag_card.type == "weapon") {
            draw_sprite(SPR_WeaponSlot, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2);
        }
    }
    
    if (action_slot.visible && !action_slot.occupied) {
        if (drag_card != undefined && drag_card.type == "action") {
            draw_sprite(SPR_ActionSlot, 0, action_slot.x + _card_w / 2, action_slot.y + _card_h / 2);
        }
    }
}

function SCR_Board_InitSlots() {
    var _card_w = 73;
    var _card_h = 101;
    
    var _x_step = 65 / 3;
    var _y_step = 92 / 3;
    
    player_monster_slots = [];
    for (var i = 0; i < 5; i++) {
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
            visible  : (i < 3),
            locked   : (i >= 3),
            hovered  : false,
            sprite   : SPR_MonsterSlot
        };
    }
    
    player_weapon_slots = [];
    for (var i = 0; i < 3; i++) {
        player_weapon_slots[i] = {
            index    : i,
            type     : "weapon",
            owner    : "player",
            occupied : false,
            card     : undefined,
            x        : 19 + (i * _x_step),
            y        : 350 + (i * _y_step) + 120,
            w        : _card_w,
            h        : _card_h,
            visible  : true,
            locked   : false,
            hovered  : false,
            sprite   : SPR_WeaponSlot
        };
    }
    
    action_slot = {
        index    : 0,
        type     : "action",
        owner    : "player",
        occupied : false,
        card     : undefined,
        x        : 84 + 50,
        y        : 442,
        w        : _card_w,
        h        : _card_h,
        visible  : true,
        locked   : false,
        hovered  : false,
        sprite   : SPR_ActionSlot
    };
    
    show_debug_message("Board slots initialized diagonally from (19,350) to (84,442)");
}

function SCR_Board_DrawPlacedCards() {
    var _card_w = 73;
    var _card_h = 101;
    
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr = SCR_Hand_GetSprite(_slot.card);
        draw_sprite(_spr, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(_slot.x + _card_w / 2, _slot.y + 5, _slot.card.name);
    }
    
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr = SCR_Hand_GetSprite(_slot.card);
        draw_sprite(_spr, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(_slot.x + _card_w / 2, _slot.y + 5, _slot.card.name);
    }
    
    if (action_slot.occupied && action_slot.card != undefined) {
        var _spr = SCR_Hand_GetSprite(action_slot.card);
        draw_sprite(_spr, 0, action_slot.x + _card_w / 2, action_slot.y + _card_h / 2);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(action_slot.x + _card_w / 2, action_slot.y + 5, action_slot.card.name);
    }
    
    for (var i = 0; i < array_length(enemy_slots); i++) {
        var _slot = enemy_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr = SCR_Hand_GetSprite(_slot.card);
        draw_sprite(_spr, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(_slot.x + _card_w / 2, _slot.y + 5, _slot.card.name);
    }
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}