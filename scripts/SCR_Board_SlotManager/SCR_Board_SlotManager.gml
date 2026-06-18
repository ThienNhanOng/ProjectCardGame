function SCR_Board_GetSlotAt(_mx, _my) {
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || _slot.locked) continue;
        if (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
            _my >= _slot.y && _my <= _slot.y + _slot.h) {
            return _slot;
        }
    }
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || _slot.locked) continue;
        if (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
            _my >= _slot.y && _my <= _slot.y + _slot.h) {
            return _slot;
        }
    }
    if (action_slot.visible) {
        if (_mx >= action_slot.x && _mx <= action_slot.x + action_slot.w &&
            _my >= action_slot.y && _my <= action_slot.y + action_slot.h) {
            return action_slot;
        }
    }
    return undefined;
}

function SCR_Board_UpdateHover(_mx, _my, _dragging_card) {
    if (_dragging_card == undefined) {
        SCR_Board_ClearHover();
        return;
    }
    var _card_type = _dragging_card.type;
    
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) {
            _slot.hovered = false;
            continue;
        }
        var _valid = (_card_type == "monster" || _card_type == "special_monster");
        _slot.hovered = _valid && (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
                                   _my >= _slot.y && _my <= _slot.y + _slot.h);
    }
    
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) {
            _slot.hovered = false;
            continue;
        }
        var _valid = (_card_type == "weapon");
        _slot.hovered = _valid && (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
                                   _my >= _slot.y && _my <= _slot.y + _slot.h);
    }
    
    if (action_slot.visible) {
        var _valid = (_card_type == "action");
        action_slot.hovered = _valid && (_mx >= action_slot.x && _mx <= action_slot.x + action_slot.w &&
                                         _my >= action_slot.y && _my <= action_slot.y + action_slot.h);
    }
}

function SCR_Board_ClearHover() {
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        player_monster_slots[i].hovered = false;
    }
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        player_weapon_slots[i].hovered = false;
    }
    for (var i = 0; i < array_length(enemy_slots); i++) {
        enemy_slots[i].hovered = false;
    }
    action_slot.hovered = false;
}

function SCR_Board_UpdateWeaponSlotAvailability() {
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _weapon_slot = player_weapon_slots[i];
        var _monster_slot = player_monster_slots[i];
        
        // If monster slot exists and is occupied
        if (_monster_slot != undefined && _monster_slot.occupied) {
            // Make weapon slot visible and unlocked
            _weapon_slot.visible = true;
            _weapon_slot.locked = false;
        } else {
            // Hide and lock weapon slot if no monster above
            _weapon_slot.visible = false;
            _weapon_slot.locked = true;
        }
    }
    show_debug_message("Weapon slot availability updated");
}

function SCR_Board_PlaceCard(_slot, _card) {
    if (_slot == undefined) return false;
    if (_slot.occupied) {
        show_debug_message("Slot already occupied!");
        return false;
    }
    if (_slot.locked) {
        show_debug_message("Slot is locked!");
        return false;
    }
    var _valid = false;
    switch (_slot.type) {
        case "monster":
            _valid = (_card.type == "monster" || _card.type == "special_monster");
            break;
        case "weapon":
            _valid = (_card.type == "weapon");
            break;
        case "action":
            _valid = (_card.type == "action");
            if (_valid) {
                var _bm = instance_find(OBJ_BattleManager, 0);
                if (_bm != noone) {
                    with (_bm) {
                        if (!battle_CanPlayActionCard(_card)) return false;
                    }
                }
            }
            break;
    }
    if (!_valid) {
        show_debug_message("Invalid card type for slot! Card: " + _card.type + " Slot: " + _slot.type);
        return false;
    }
    _slot.occupied = true;
    _slot.card = _card;
    _slot.hovered = false;
    show_debug_message("Placed " + _card.name + " in " + _slot.type + " slot " + string(_slot.index));
    
    battle_NotifyCardPlaced(_slot, _card);
    
    // If this was a monster slot, update weapon slot availability
    if (_slot.type == "monster") {
        SCR_Board_UpdateWeaponSlotAvailability();
    }
    
    return true;
}

function SCR_Board_RemoveCard(_slot) {
    if (_slot == undefined || !_slot.occupied) return undefined;
    var _card = _slot.card;
    var _slot_type = _slot.type;
    var _slot_index = _slot.index;
    
    _slot.occupied = false;
    _slot.card = undefined;
    show_debug_message("Removed " + _card.name + " from slot " + string(_slot_index));
    
    // If this was a monster slot, update weapon slot availability
    if (_slot_type == "monster") {
        SCR_Board_UpdateWeaponSlotAvailability();
    }
    
    return _card;
}

function SCR_Board_UnlockSlot(_index) {
    if (_index >= 3 && _index < 5) {
        player_monster_slots[_index].visible = true;
        player_monster_slots[_index].locked = false;
        // Don't auto-unlock weapon slot - it will unlock when monster is placed
        // player_weapon_slots[_index].visible = true;
        // player_weapon_slots[_index].locked = false;
        show_debug_message("Unlocked monster slot: " + string(_index));
        
        // Update weapon slot availability based on monster occupation
        SCR_Board_UpdateWeaponSlotAvailability();
    }
}

function SCR_Board_SetEnemySlots(_count) {
    for (var i = 0; i < array_length(enemy_slots); i++) {
        enemy_slots[i].visible = (i < _count);
    }
    show_debug_message("Enemy slots active: " + string(_count));
}