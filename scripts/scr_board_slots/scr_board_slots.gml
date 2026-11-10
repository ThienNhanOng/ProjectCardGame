/// @desc Board slots — hover, place/remove cards, opening / closing the back row (openzone)

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

/// Is your monster spot _index open and empty (somewhere a monster can go)?
function battle_IsFreeMonsterSpot(_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _index < 0 || _index >= array_length(_board.player_monster_slots)) return false;
    var _s = _board.player_monster_slots[_index];
    return _s.visible && !_s.locked && !_s.occupied;
}

/// Can this summon trait happen now? Its card must be a monster card and there must be a free spot.
function battle_CanSummon(_trait) {
    var _def = deck_GetCardData(_trait.card_id);
    return _def != undefined && _def.type == "monster" && battle_HasFreeMonsterSpot();
}

function battle_HasFreeMonsterSpot() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        if (battle_IsFreeMonsterSpot(i)) return true;
    }
    return false;
}

/// Cards that go into a monster slot
function SCR_Board_IsMonsterCard(_card) {
    return _card != undefined && (_card.type == "monster" || _card.type == "special_monster" || _card.type == "spirit");
}

/// Your monster slot under a point, or -1. _occupied: the top-most unit there (units can overlap);
/// otherwise the empty open spot under the point whose centre is closest.
function SCR_Board_MonsterSlotAt(_mx, _my, _occupied) {
    if (_occupied) return unit_GetSlotAt(SIDE_PLAYER, _mx, _my);

    var _best = -1;
    var _best_dist = infinity;
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _s = player_monster_slots[i];
        if (!_s.visible || _s.locked || _s.occupied) continue;
        if (!point_in_rectangle(_mx, _my, _s.x, _s.y, _s.x + _s.w, _s.y + _s.h)) continue;
        var _dist = point_distance(_mx, _my, _s.x + _s.w / 2, _s.y + _s.h / 2);
        if (_dist < _best_dist) {
            _best_dist = _dist;
            _best = i;
        }
    }
    return _best;
}

/// Can a weapon / action card be dropped on your monster in slot _i?
function SCR_Board_CanDropOnMonster(_i, _card) {
    if (_card == undefined || _i < 0 || _i >= array_length(player_monster_slots)) return false;
    var _ms = player_monster_slots[_i];
    if (!_ms.visible || _ms.locked || !_ms.occupied || _ms.card == undefined) return false;
    if (_card.type == "weapon") {
        var _ws = player_weapon_slots[_i];
        return !_ws.occupied && !_ws.locked;
    }
    if (_card.type == "action") return !action_slot.occupied;
    return false;
}

/// Where the dragged card would go: { slot, monster } or undefined
///   monster / spirit card -> an empty monster spot
///   weapon -> that monster's weapon slot     action -> the action slot, acted out by that monster
function SCR_Board_GetDropTarget(_mx, _my, _card) {
    if (_card == undefined) return undefined;
    if (SCR_Board_IsMonsterCard(_card)) {
        var _empty = SCR_Board_MonsterSlotAt(_mx, _my, false);
        return (_empty >= 0) ? { slot: player_monster_slots[_empty], monster: _empty } : undefined;
    }
    var _m = SCR_Board_MonsterSlotAt(_mx, _my, true);
    if (!SCR_Board_CanDropOnMonster(_m, _card)) return undefined;
    return { slot: (_card.type == "weapon") ? player_weapon_slots[_m] : action_slot, monster: _m };
}

/// The weapon card whose chip (bottom-left of a monster card) is under the point, or undefined
function SCR_Board_WeaponChipAt(_mx, _my) {
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _ws = player_weapon_slots[i];
        if (!_ws.occupied || _ws.card == undefined) continue;
        var _ms = player_monster_slots[i];
        if (point_distance(_mx, _my, _ms.x + 10, _ms.y + _ms.h - 12) <= 17) return _ws.card;
    }
    return undefined;
}

function SCR_Board_UpdateHover(_mx, _my, _dragging_card, _drag_hand_index = -1) {
    if (_dragging_card == undefined) {
        SCR_Board_ClearHover();
        return;
    }
    var _card_type = _dragging_card.type;
    var _can_pay = card_CanAffordAllCosts(_dragging_card, _drag_hand_index);
    
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) {
            _slot.hovered = false;
            continue;
        }
        var _valid = (_card_type == "monster" || _card_type == "special_monster") && _can_pay;
        _slot.hovered = _valid && (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
                                   _my >= _slot.y && _my <= _slot.y + _slot.h);
    }
    
    for (var i = 0; i < array_length(player_weapon_slots); i++) {
        var _slot = player_weapon_slots[i];
        if (!_slot.visible || _slot.locked || _slot.occupied) {
            _slot.hovered = false;
            continue;
        }
        var _valid = (_card_type == "weapon") && _can_pay;
        _slot.hovered = _valid && (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
                                   _my >= _slot.y && _my <= _slot.y + _slot.h);
    }
    
    if (action_slot.visible) {
        var _valid = (_card_type == "action") && _can_pay;
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
}

/// Put a card in a slot. _defer_on_play: a monster summoned by another card — its on-play abilities
/// wait until that card's play is finished (battle_RunDeferredOnPlay).
function SCR_Board_PlaceCard(_slot, _card, _defer_on_play = false) {
    if (_slot == undefined) return false;
    if (_slot.occupied) {
        return false;
    }
    if (_slot.locked) {
        return false;
    }
    var _valid = false;
    switch (_slot.type) {
        case "monster":
            _valid = (_card.type == "monster" || _card.type == "special_monster" || _card.type == "spirit");
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
        return false;
    }
    _slot.occupied = true;
    _slot.card = _card;
    _slot.hovered = false;
    if (_slot.type == "monster") battlefx_Arrive(_card, SIDE_PLAYER, _slot.index, 0);   // hops in from the left
    battle_NotifyCardPlaced(_slot, _card, _defer_on_play);
    
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
    // If this was a monster slot, update weapon slot availability
    if (_slot_type == "monster") {
        SCR_Board_UpdateWeaponSlotAvailability();
    }
    
    return _card;
}

/// Open back-row spot _index for the monster in column _owner_slot (openzone). False when it is already open.
function SCR_Board_OpenBackSlot(_index, _owner_slot) {
    var _slot = player_monster_slots[_index];
    if (!_slot.locked) return false;
    _slot.visible = true;
    _slot.locked = false;
    _slot.opened_by = _owner_slot;
    return true;
}

/// Close back-row spot _index again. The monster standing there has already left (battle_CloseBackRowSpotsOf).
function SCR_Board_CloseBackSlot(_index) {
    var _slot = player_monster_slots[_index];
    _slot.visible = false;
    _slot.locked = true;
    _slot.opened_by = -1;
    SCR_Board_UpdateWeaponSlotAvailability();
}

function SCR_Board_SetEnemySlots(_count) {
    for (var i = 0; i < array_length(enemy_slots); i++) {
        enemy_slots[i].visible = (i < _count);
    }
}
