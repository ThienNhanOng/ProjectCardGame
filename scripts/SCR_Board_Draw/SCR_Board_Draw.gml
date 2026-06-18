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

function SCR_Board_IsSlotMouseOver(_slot) {
    var _card_w = 73;
    var _card_h = 101;
    var _left   = _slot.x;
    var _top    = _slot.y;
    var _right  = _slot.x + _card_w;
    var _bottom = _slot.y + _card_h;
    
    return (mouse_x >= _left && mouse_x <= _right &&
            mouse_y >= _top  && mouse_y <= _bottom);
}

function SCR_Board_DrawPlayerMonsterOverlay(_slot, _card_w, _card_h) {
    if (_slot == undefined || !_slot.visible || !_slot.occupied || _slot.card == undefined) return;

    battle_EnsureCardHealth(_slot.card);

    var _cx = _slot.x + _card_w / 2;
    var _bar_pad = 4;
    // Sit above the weapon slot (weapon y overlaps the bottom of the monster card)
    var _bar_y = _slot.y + _card_h - 26;
    monster_DrawHealthBar(_slot.x + _bar_pad, _bar_y, _card_w - _bar_pad * 2, 8,
        _slot.card.health, _slot.card.max_health);

    var _attack_gain = card_GetAttackBuff(_slot.card);
    card_DrawAttackGainBadge(_slot.x, _slot.y, _card_w, _card_h, _attack_gain);

    var _pstatus = status_GetDisplayText(_slot.card);
    if (_pstatus != "") {
        draw_set_color(c_orange);
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_text(_cx, _bar_y - 12, _pstatus);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function SCR_Board_DrawPlacedCards() {
    var _card_w = 73;
    var _card_h = 101;
    var _hover_scale = 1.3;
    
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr     = SCR_Hand_GetSprite(_slot.card);
        var _hovered = !is_dragging && SCR_Board_IsSlotMouseOver(_slot);
        var _scale   = _hovered ? _hover_scale : 1;
        var _cx      = _slot.x + _card_w / 2;
        var _cy      = _slot.y + _card_h / 2;

        draw_sprite_ext(_spr, 0, _cx, _cy, _scale, _scale, 0, c_white, 1);
        draw_set_color(c_black);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_text(_slot.x + 4, _slot.y + 5, SCR_Hand_TruncateName(_slot.card.name, _card_w - 8));
    }
    
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        var _spr     = SCR_Hand_GetSprite(_slot.card);
        var _hovered = !is_dragging && SCR_Board_IsSlotMouseOver(_slot);
        var _scale   = _hovered ? _hover_scale : 1;
        
        draw_sprite_ext(_spr, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2, _scale, _scale, 0, c_white, 1);
        draw_set_color(c_black);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_text(_slot.x + 4, _slot.y + 5, SCR_Hand_TruncateName(_slot.card.name, _card_w - 8));

        var _weapon_atk = weapon_GetAttackAmount(_slot.card);
        card_DrawAttackGainBadge(_slot.x, _slot.y, _card_w, _card_h, _weapon_atk);

        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) {
                if (battle_CanWeaponAttack(i)) {
                    draw_set_color(c_yellow);
                    draw_rectangle(_slot.x - 2, _slot.y - 2, _slot.x + _card_w + 2, _slot.y + _card_h + 2, true);
                } else if (i < array_length(weapon_attacks_used) && weapon_attacks_used[i]) {
                    draw_set_color(c_gray);
                    draw_text(_slot.x + _card_w / 2, _slot.y + _card_h + 2, "used");
                }
            }
        }
    }

    for (var m = 0; m < array_length(player_monster_slots); m++) {
        SCR_Board_DrawPlayerMonsterOverlay(player_monster_slots[m], _card_w, _card_h);
    }
    
    if (action_slot.occupied && action_slot.card != undefined) {
        var _spr     = SCR_Hand_GetSprite(action_slot.card);
        var _hovered = !is_dragging && SCR_Board_IsSlotMouseOver(action_slot);
        var _scale   = _hovered ? _hover_scale : 1;
        
        draw_sprite_ext(_spr, 0, action_slot.x + _card_w / 2, action_slot.y + _card_h / 2, _scale, _scale, 0, c_white, 1);
        draw_set_color(c_black);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_text(action_slot.x + 4, action_slot.y + 5, SCR_Hand_TruncateName(action_slot.card.name, _card_w - 8));
    }
    
    // Enemy slots are drawn by OBJ_MonsterManager
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}