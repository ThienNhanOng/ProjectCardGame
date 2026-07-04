/// @desc Silence — blocks enemy ability use. Shroud — blocks player monster attacks.

function trait_CreateSilenceContext(_turns, _target_side, _target_slot) {
    return {
        trait_type: "silence",
        amount: _turns,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}

function trait_CreateShroudContext(_turns, _target_player_slot) {
    return {
        trait_type: "shroud",
        amount: _turns,
        target_side: "player",
        target_enemy_slot: -1,
        target_player_slot: _target_player_slot
    };
}

function trait_ExecuteSilence(_ctx) {
    _ctx.amount = floor(max(1, real(_ctx.amount)));

    if (_ctx.target_side == "enemy" && _ctx.target_enemy_slot >= 0) {
        return battle_SilenceEnemyMonster(_ctx.target_enemy_slot, _ctx.amount);
    }

    if (_ctx.target_side == "player" && _ctx.target_player_slot >= 0) {
        return battle_ShroudPlayerMonster(_ctx.target_player_slot, _ctx.amount);
    }

    return false;
}

function trait_ExecuteShroud(_ctx) {
    _ctx.amount = floor(max(1, real(_ctx.amount)));

    if (_ctx.target_player_slot < 0) return false;
    return battle_ShroudPlayerMonster(_ctx.target_player_slot, _ctx.amount);
}

function battle_SilenceEnemyMonster(_slot_index, _turns) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return false;
    if (_slot_index < 0 || _slot_index >= _mm.active_slot_count) return false;

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) return false;

    if (!status_SilenceUnit(_slot.card, _turns)) return false;

    battle_StatusLog_Silence("enemy", _slot_index, _slot.card.name, _slot.card.silenced_turns);
return true;
}

function battle_ShroudPlayerMonster(_slot_index, _turns) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.visible || !_slot.occupied || _slot.card == undefined) return false;

    if (!status_ShroudUnit(_slot.card, _turns)) return false;

    battle_StatusLog_Shroud(_slot_index, _slot.card.name, _slot.card.shrouded_turns);
return true;
}

function battle_SilencePlayerMonster(_slot_index, _turns) {
    return battle_ShroudPlayerMonster(_slot_index, _turns);
}

function battle_StatusLog_Shroud(_slot_index, _unit_name, _turns) {
    var _turn = battle_EnemyLog_GetTurn();
    battle_EnemyLog_Write("Turn " + string(_turn)
        + " | SHROUD | " + _unit_name + " (player slot " + string(_slot_index) + ")"
        + " | " + string(_turns) + " turn(s)");
}
