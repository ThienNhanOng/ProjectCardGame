/// @desc Shared buff_attack trait — increases target monster attack stat

function trait_ExecuteBuffAttack(_ctx) {
    if (_ctx.amount <= 0) return false;

    if (_ctx.target_side == "enemy") {
        return battle_BuffEnemyMonster(_ctx.target_enemy_slot, _ctx.amount);
    }

    return false;
}

function trait_CreateBuffAttackContext(_amount, _target_side, _target_slot) {
    return {
        trait_type: "buff_attack",
        amount: _amount,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}

function battle_BuffEnemyMonster(_slot_index, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return false;
    if (_slot_index < 0 || _slot_index >= _mm.active_slot_count) return false;

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) return false;

    _slot.card.attack += _amount;
    show_debug_message("Buffed enemy slot " + string(_slot_index)
        + " ATK +" + string(_amount) + " -> " + string(_slot.card.attack));
    return true;
}
