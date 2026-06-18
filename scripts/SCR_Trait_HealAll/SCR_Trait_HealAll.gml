/// @desc Heal all player monsters on the board, or all enemies when target_side is enemy

function trait_ExecuteHealAll(_ctx) {
    if (_ctx.amount <= 0) return false;

    if (variable_struct_exists(_ctx, "target_side") && _ctx.target_side == "enemy") {
        return trait_HealAllEnemies(_ctx.amount);
    }

    return trait_HealAllPlayerMonsters(_ctx.amount);
}

function trait_HealAllPlayerMonsters(_amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _healed = false;
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        if (battle_HealPlayerMonster(i, _amount)) _healed = true;
    }

    show_debug_message("Heal all player monsters for " + string(_amount));
    return _healed;
}

function trait_HealAllEnemies(_amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return false;

    var _healed = false;
    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;
        if (battle_HealEnemyMonster(i, _amount)) _healed = true;
    }

    show_debug_message("Heal all enemies for " + string(_amount));
    return _healed;
}

function trait_CreateHealAllContext(_amount, _target_side = "player") {
    return {
        trait_type: "heal_all",
        amount: _amount,
        target_side: _target_side
    };
}
