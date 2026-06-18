/// @desc Destroy enemy or player monsters (amount = targets to destroy, or damage if use_damage)

function trait_CreateDestroyContext(_amount, _target_side, _target_slot) {
    return {
        trait_type: "destroy",
        amount: _amount,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}

function battle_DestroyEnemyMonster(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return false;
    if (_slot_index < 0 || _slot_index >= _mm.active_slot_count) return false;

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) return false;

    show_debug_message(_slot.card.name + " destroyed in enemy slot " + string(_slot_index));
    _slot.occupied = false;
    _slot.card = undefined;

    with (_mm) {
        monster_SpawnIntoSlot(_board, _slot_index);
        monster_CheckVictory(_board);
    }
    return true;
}

function trait_ExecuteDestroy(_ctx) {
    if (_ctx.amount <= 0) _ctx.amount = 1;

    if (_ctx.target_side == "enemy" && _ctx.target_enemy_slot >= 0) {
        return battle_DestroyEnemyMonster(_ctx.target_enemy_slot);
    }

    if (_ctx.target_side == "player" && _ctx.target_player_slot >= 0) {
        return battle_DestroyPlayerMonster(_ctx.target_player_slot);
    }

    return trait_DestroyEnemyCount(_ctx.amount);
}

function trait_DestroyEnemyCount(_count) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return false;

    var _destroyed = 0;
    for (var n = 0; n < _count; n++) {
        var _target = trait_PickLowestHpEnemySlot();
        if (_target < 0) break;
        if (battle_DestroyEnemyMonster(_target)) _destroyed++;
    }

    return _destroyed > 0;
}

function trait_PickLowestHpEnemySlot() {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return -1;

    var _best = -1;
    var _best_hp = infinity;

    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;
        if (_slot.card.health < _best_hp) {
            _best_hp = _slot.card.health;
            _best = i;
        }
    }

    return _best;
}
