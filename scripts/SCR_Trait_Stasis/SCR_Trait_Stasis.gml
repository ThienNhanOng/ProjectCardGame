/// @desc Stasis — apply a DoT type from datafiles/DoT_*.json (burn, poison, etc.)

function trait_CreateStasisContext(_dot_type, _damage, _duration, _target_side, _target_slot) {
    return {
        trait_type: "stasis",
        dot_type: _dot_type,
        amount: _damage,
        duration: _duration,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}

function trait_ExecuteStasis(_ctx) {
    if (_ctx.dot_type == "") return false;

    if (_ctx.target_side == "enemy" && _ctx.target_enemy_slot >= 0) {
        return battle_ApplyStasisEnemy(_ctx.target_enemy_slot, _ctx.dot_type, _ctx.amount, _ctx.duration);
    }

    if (_ctx.target_side == "player" && _ctx.target_player_slot >= 0) {
        return battle_ApplyStasisPlayer(_ctx.target_player_slot, _ctx.dot_type, _ctx.amount, _ctx.duration);
    }

    return false;
}

function battle_ApplyStasisEnemy(_slot_index, _dot_type, _damage, _duration) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return false;
    if (_slot_index < 0 || _slot_index >= _mm.active_slot_count) return false;

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) return false;

    if (!status_ApplyDoT(_slot.card, _dot_type, _damage, _duration)) return false;

    var _def = dot_GetDefinition(_dot_type);
    var _dmg = (_damage > 0) ? _damage : _def.damage_per_tick;
    var _dur = (_duration > 0) ? _duration : _def.default_duration;

    battle_StatusLog_Stasis("enemy", _slot_index, _slot.card.name, _dot_type, _dmg, _dur);
    show_debug_message("Stasis " + _dot_type + " on " + _slot.card.name
        + " (" + string(_dmg) + " x " + string(_dur) + " ticks)");
    return true;
}

function battle_ApplyStasisPlayer(_slot_index, _dot_type, _damage, _duration) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.visible || !_slot.occupied || _slot.card == undefined) return false;

    if (!status_ApplyDoT(_slot.card, _dot_type, _damage, _duration)) return false;

    var _def = dot_GetDefinition(_dot_type);
    var _dmg = (_damage > 0) ? _damage : _def.damage_per_tick;
    var _dur = (_duration > 0) ? _duration : _def.default_duration;

    battle_StatusLog_Stasis("player", _slot_index, _slot.card.name, _dot_type, _dmg, _dur);
    return true;
}
