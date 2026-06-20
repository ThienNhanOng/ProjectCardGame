/// @desc Shared buff trait — self_buff targets own slot; buff targets any monster

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

function card_GetSummaryTotalAttack(_card) {
    if (_card == undefined) return 0;

    if (variable_struct_exists(_card, "attack")) {
        return max(0, floor(_card.attack));
    }

    if (variable_struct_exists(_card, "base_attack")) {
        return max(0, floor(_card.base_attack)) + card_GetAttackBuff(_card);
    }

    if (battle_IsSpiritMonster(_card)) {
        return battle_GetMonsterStrikeAmount(_card) + card_GetAttackBuff(_card);
    }

    return card_GetAttackBuff(_card);
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
        trait_type: "buff",
        amount: _amount,
        target_side: _target_side,
        target_enemy_slot: (_target_side == "enemy") ? _target_slot : -1,
        target_player_slot: (_target_side == "player") ? _target_slot : -1
    };
}

function battle_ExecuteBuffAt(_side, _slot_index, _amount) {
    if (_amount <= 0) return false;
    if (_side == "player") return battle_BuffPlayerMonster(_slot_index, _amount);
    if (_side == "enemy") return battle_BuffEnemyMonster(_slot_index, _amount);
    return false;
}

function battle_PickRandomAnyBuffTarget() {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone) return { side: "", slot: -1 };

    var _choices = [];

    for (var p = 0; p < array_length(_board.player_monster_slots); p++) {
        var _pslot = _board.player_monster_slots[p];
        if (_pslot.visible && _pslot.occupied && _pslot.card != undefined) {
            array_push(_choices, { side: "player", slot: p });
        }
    }

    if (_mm != noone) {
        for (var e = 0; e < _mm.active_slot_count; e++) {
            var _eslot = _board.enemy_slots[e];
            if (_eslot.visible && _eslot.occupied && _eslot.card != undefined && _eslot.card.alive) {
                array_push(_choices, { side: "enemy", slot: e });
            }
        }
    }

    if (array_length(_choices) == 0) return { side: "", slot: -1 };
    return _choices[irandom(array_length(_choices) - 1)];
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
