/// @desc Shared attack trait — used by weapons, action cards, and monster abilities

function trait_ExecuteAttack(_ctx) {
    if (_ctx.amount <= 0) return false;

    if (_ctx.target_side == "enemy") {
        var _mm = instance_find(OBJ_MonsterManager, 0);
        if (_mm == noone) return false;
        with (_mm) {
            monster_ApplyDamage(_ctx.target_enemy_slot, _ctx.amount);
        }
return true;
    }

    if (_ctx.target_side == "player") {
        return battle_DamagePlayerSide(_ctx.amount, _ctx.target_player_slot);
    }

    return false;
}

function trait_CreateAttackContext(_amount, _target_side, _target_slot) {
    return {
        trait_type: "attack",
        amount: _amount,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}
