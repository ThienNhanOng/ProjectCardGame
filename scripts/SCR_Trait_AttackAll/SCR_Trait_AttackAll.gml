/// @desc Damage all active enemy monsters, or all player monsters when target_side is player

function trait_ExecuteAttackAll(_ctx) {
    if (_ctx.amount <= 0) return false;

    if (variable_struct_exists(_ctx, "target_side") && _ctx.target_side == "player") {
        return trait_AttackAllPlayerMonsters(_ctx.amount);
    }

    return trait_AttackAllEnemies(_ctx.amount);
}

function trait_AttackAllEnemies(_amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return false;

    var _hit = false;
    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;

        with (_mm) {
            monster_ApplyDamage(i, _amount);
        }
        _hit = true;
    }

return _hit;
}

function trait_AttackAllPlayerMonsters(_amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return battle_DamagePlayer(_amount);

    var _hit = false;
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        battle_DamagePlayerMonster(i, _amount);
        _hit = true;
    }

    if (!_hit) return battle_DamagePlayer(_amount);

return true;
}

function trait_CreateAttackAllContext(_amount, _target_side = "enemy") {
    return {
        trait_type: "attack_all",
        amount: _amount,
        target_side: _target_side
    };
}
