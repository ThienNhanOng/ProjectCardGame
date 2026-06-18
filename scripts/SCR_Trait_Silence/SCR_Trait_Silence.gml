/// @desc Silence — blocks enemy ability use for N enemy turns

function trait_CreateSilenceContext(_turns, _target_side, _target_slot) {
    return {
        trait_type: "silence",
        amount: _turns,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}

function trait_ExecuteSilence(_ctx) {
    _ctx.amount = floor(max(1, real(_ctx.amount)));

    if (_ctx.target_side == "enemy" && _ctx.target_enemy_slot >= 0) {
        return battle_SilenceEnemyMonster(_ctx.target_enemy_slot, _ctx.amount);
    }

    if (_ctx.target_side == "player" && _ctx.target_player_slot >= 0) {
        return battle_SilencePlayerMonster(_ctx.target_player_slot, _ctx.amount);
    }

    return false;
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
    show_debug_message("Silenced " + _slot.card.name + " for " + string(_slot.card.silenced_turns)
        + " enemy turn(s) | ability set to none");
    return true;
}

function battle_SilencePlayerMonster(_slot_index, _turns) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.visible || !_slot.occupied || _slot.card == undefined) return false;

    if (!status_SilenceUnit(_slot.card, _turns)) return false;

    battle_StatusLog_Silence("player", _slot_index, _slot.card.name, _turns);
    show_debug_message("Silenced player " + _slot.card.name + " for " + string(_turns) + " turn(s)");
    return true;
}
