/// @desc Shared heal trait — used by action cards, weapons, and monster abilities

function trait_ExecuteHeal(_ctx) {
    if (_ctx.amount <= 0) return false;

    if (_ctx.target_side == "player") {
        return battle_HealPlayerMonster(_ctx.target_player_slot, _ctx.amount);
    }

    if (_ctx.target_side == "enemy") {
        return battle_HealEnemyMonster(_ctx.target_enemy_slot, _ctx.amount);
    }

    return false;
}

function trait_CreateHealContext(_amount, _target_side, _target_slot) {
    return {
        trait_type: "heal",
        amount: _amount,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}

function battle_HealPlayerMonster(_slot_index, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined) return false;

    battle_EnsureCardHealth(_slot.card);
    _slot.card.health = min(_slot.card.max_health, _slot.card.health + _amount);
    show_debug_message("Healed player slot " + string(_slot_index) + " for " + string(_amount));
    return true;
}

function battle_HealEnemyMonster(_slot_index, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.enemy_slots)) return false;

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) return false;

    _slot.card.health = min(_slot.card.max_health, _slot.card.health + _amount);
    show_debug_message("Healed enemy slot " + string(_slot_index) + " for " + string(_amount));
    return true;
}

function battle_DamagePlayerMonster(_slot_index, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined) return false;

    battle_EnsureCardHealth(_slot.card);
    _slot.card.health = max(0, _slot.card.health - _amount);
    show_debug_message("Player slot " + string(_slot_index) + " took " + string(_amount) + " damage"
        + " | HP: " + string(_slot.card.health) + "/" + string(_slot.card.max_health));

    if (_slot.card.health <= 0) {
        battle_DestroyPlayerMonster(_slot_index);
    }
    return true;
}

function battle_DestroyPlayerMonster(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _monster_slot = _board.player_monster_slots[_slot_index];
    if (!_monster_slot.occupied || _monster_slot.card == undefined) return false;

    var _name = _monster_slot.card.name;

    with (_board) {
        var _weapon_slot = player_weapon_slots[_slot_index];
        if (_weapon_slot.occupied && _weapon_slot.card != undefined) {
            SCR_Board_RemoveCard(_weapon_slot);
        }
        SCR_Board_RemoveCard(_monster_slot);
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) {
            if (_slot_index == pending_player_slot) battle_CancelTargeting();
            if (_slot_index < array_length(weapon_attacks_used)) {
                weapon_attacks_used[_slot_index] = false;
            }
        }
    }

    show_debug_message(_name + " destroyed in player slot " + string(_slot_index));
    return true;
}

function battle_EnsureCardHealth(_card) {
    if (_card == undefined) return;

    var _base = card_GetDefinitionHealth(_card);
    if (!variable_struct_exists(_card, "max_health")) {
        _card.max_health = _base;
    }
    if (!variable_struct_exists(_card, "health")) {
        _card.health = _card.max_health;
    }
}
