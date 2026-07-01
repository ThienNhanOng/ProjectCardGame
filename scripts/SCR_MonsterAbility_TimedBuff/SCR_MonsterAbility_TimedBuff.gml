/// @desc Timed attack buff tracking for enemy self_buff and buff abilities

function monsterAbility_InitTimedBuffs(_card) {
    if (_card == undefined) return;
    if (!variable_struct_exists(_card, "timed_attack_buffs") || !is_array(_card.timed_attack_buffs)) {
        _card.timed_attack_buffs = [];
    }
}

function monsterAbility_ApplyTimedBuff(_card, _amount, _turns, _source_name = "") {
    if (_card == undefined || _amount <= 0 || _turns <= 0) return;
    monsterAbility_InitTimedBuffs(_card);
    array_push(_card.timed_attack_buffs, {
        amount: _amount,
        turns_left: _turns,
        source_name: string(_source_name)
    });
}

function monsterAbility_TickAllTimedBuffs() {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone) return;

    if (_mm != noone) {
        for (var e = 0; e < _mm.active_slot_count; e++) {
            var _eslot = _board.enemy_slots[e];
            if (_eslot.occupied && _eslot.card != undefined && _eslot.card.alive) {
                monsterAbility_TickTimedBuffsOnUnit(_eslot.card);
            }
        }
    }

    for (var p = 0; p < array_length(_board.player_monster_slots); p++) {
        var _pslot = _board.player_monster_slots[p];
        if (_pslot.visible && _pslot.occupied && _pslot.card != undefined) {
            monsterAbility_TickTimedBuffsOnUnit(_pslot.card);
        }
    }
}

function monsterAbility_TickTimedBuffsOnUnit(_card) {
    monsterAbility_InitTimedBuffs(_card);
    if (array_length(_card.timed_attack_buffs) <= 0) return;

    for (var i = array_length(_card.timed_attack_buffs) - 1; i >= 0; i--) {
        _card.timed_attack_buffs[i].turns_left--;
        if (_card.timed_attack_buffs[i].turns_left <= 0) {
            var _expired = _card.timed_attack_buffs[i].amount;
            _card.attack = max(0, _card.attack - _expired);
            if (variable_struct_exists(_card, "attack_buff")) {
                _card.attack_buff = max(0, _card.attack_buff - _expired);
            }
            array_delete(_card.timed_attack_buffs, i, 1);
        }
    }
}
