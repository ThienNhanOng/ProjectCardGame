/// @desc Shared buff_attack trait — increases target monster attack stat

function card_GainAttack(_card, _amount) {
    if (_card == undefined || _amount <= 0) return;

    if (!variable_struct_exists(_card, "attack")) _card.attack = 0;
    if (!variable_struct_exists(_card, "attack_buff")) _card.attack_buff = 0;

    _card.attack += _amount;
    _card.attack_buff += _amount;
}

function card_GetAttackBuff(_card) {
    if (_card == undefined) return 0;
    if (!variable_struct_exists(_card, "attack_buff")) return 0;
    return max(0, floor(_card.attack_buff));
}

function card_DrawAttackGainBadge(_x, _y, _w, _h, _amount) {
    if (_amount <= 0) return;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_red);
    draw_text(_x + _w / 2, _y + _h / 2 + 2, "+" + string(_amount));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function trait_ExecuteBuffAttack(_ctx) {
    if (_ctx.amount <= 0) return false;

    if (_ctx.target_side == "enemy") {
        return battle_BuffEnemyMonster(_ctx.target_enemy_slot, _ctx.amount);
    }

    if (_ctx.target_side == "player" && _ctx.target_player_slot >= 0) {
        return battle_BuffPlayerMonster(_ctx.target_player_slot, _ctx.amount);
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

    if (!variable_struct_exists(_slot.card, "attack_buff")) _slot.card.attack_buff = 0;
    card_GainAttack(_slot.card, _amount);
    show_debug_message("Buffed enemy slot " + string(_slot_index)
        + " ATK +" + string(_amount) + " -> " + string(_slot.card.attack));
    return true;
}

function battle_BuffPlayerMonster(_slot_index, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.visible || !_slot.occupied || _slot.card == undefined) return false;

    card_GainAttack(_slot.card, _amount);
    show_debug_message("Buffed player slot " + string(_slot_index)
        + " ATK +" + string(_amount) + " -> " + string(_slot.card.attack));
    return true;
}
