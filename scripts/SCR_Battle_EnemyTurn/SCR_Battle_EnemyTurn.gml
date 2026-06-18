/// @desc Enemy turn — each monster uses an effect OR attacks (elite: both)

function battle_EnemyHasEffect(_monster) {
    if (status_IsSilenced(_monster)) return false;

    var _traits = trait_GetFromMonster(_monster);
    for (var i = 0; i < array_length(_traits); i++) {
        var _type = _traits[i].type;
        if (_type != "none" && _type != "attack") return true;
    }
    return false;
}

function battle_EnemyPickHealTarget(_preferred_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return _preferred_slot;

    var _best = _preferred_slot;
    var _best_ratio = 1;

    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;

        var _ratio = (_slot.card.max_health > 0) ? _slot.card.health / _slot.card.max_health : 0;
        if (_ratio < _best_ratio) {
            _best_ratio = _ratio;
            _best = i;
        }
    }

    return _best;
}

function battle_EnemyPickBuffTarget(_source_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return _source_slot;

    var _best = _source_slot;
    var _best_atk = infinity;

    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;

        if (_slot.card.attack < _best_atk) {
            _best_atk = _slot.card.attack;
            _best = i;
        }
    }

    return _best;
}

function battle_EnemyUseEffectTrait(_enemy_slot_index, _monster, _trait) {
    if (_trait == undefined) return false;
    if (status_IsSilenced(_monster)) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    switch (_trait.type) {
        case "heal":
            var _heal_target = battle_EnemyPickHealTarget(_enemy_slot_index);
            var _heal_slot = _board.enemy_slots[_heal_target];
            var _hp_before = _heal_slot.card.health;
            var _hp_max = _heal_slot.card.max_health;
            var _heal_ok = trait_Execute(_trait, trait_CreateHealContext(_trait.amount, "enemy", _heal_target));
            if (_heal_ok) {
                battle_EnemyLog_Heal(_enemy_slot_index, _monster, _heal_target, _trait.amount,
                    _hp_before, _heal_slot.card.health, _hp_max);
            }
            return _heal_ok;

        case "heal_all":
            var _heal_all_ok = trait_Execute(_trait, trait_CreateHealAllContext(_trait.amount, "enemy"));
            if (_heal_all_ok) {
                battle_EnemyLog_Write("Turn " + string(battle_EnemyLog_GetTurn())
                    + " | " + _monster.name + " (slot " + string(_enemy_slot_index) + ")"
                    + " | ABILITY heal_all +" + string(_trait.amount));
            }
            return _heal_all_ok;

        case "buff_attack":
            var _buff_target = battle_EnemyPickBuffTarget(_enemy_slot_index);
            var _buff_slot = _board.enemy_slots[_buff_target];
            var _atk_before = _buff_slot.card.attack;
            var _buff_ok = trait_Execute(_trait, trait_CreateBuffAttackContext(_trait.amount, "enemy", _buff_target));
            if (_buff_ok) {
                battle_EnemyLog_BuffAttack(_enemy_slot_index, _monster, _buff_target, _trait.amount,
                    _atk_before, _buff_slot.card.attack);
            }
            return _buff_ok;

        case "attack_all":
            var _atk_all_ok = trait_Execute(_trait, trait_CreateAttackAllContext(_trait.amount, "player"));
            if (_atk_all_ok) {
                battle_EnemyLog_Write("Turn " + string(battle_EnemyLog_GetTurn())
                    + " | " + _monster.name + " (slot " + string(_enemy_slot_index) + ")"
                    + " | ABILITY attack_all " + string(_trait.amount));
            }
            return _atk_all_ok;

        case "destroy":
            var _player_target = battle_PickRandomPlayerMonsterSlot();
            if (_player_target < 0) {
                battle_EnemyLog_Skipped(_enemy_slot_index, _monster, "no player target for destroy");
                return false;
            }
            var _destroy_ok = trait_Execute(_trait, trait_CreateDestroyContext(_trait.amount, "player", _player_target));
            if (_destroy_ok) {
                battle_EnemyLog_Write("Turn " + string(battle_EnemyLog_GetTurn())
                    + " | " + _monster.name + " (slot " + string(_enemy_slot_index) + ")"
                    + " | ABILITY destroy " + string(_trait.amount));
            }
            return _destroy_ok;

        case "silence":
            var _silence_target = battle_PickRandomPlayerMonsterSlot();
            if (_silence_target < 0) return false;
            var _silence_ok = trait_Execute(_trait, trait_CreateSilenceContext(max(1, _trait.amount), "player", _silence_target));
            if (_silence_ok) {
                battle_EnemyLog_Write("Turn " + string(battle_EnemyLog_GetTurn())
                    + " | " + _monster.name + " (slot " + string(_enemy_slot_index) + ")"
                    + " | ABILITY silence -> player slot " + string(_silence_target));
            }
            return _silence_ok;

        case "stasis":
            var _stasis_target = battle_PickRandomPlayerMonsterSlot();
            if (_stasis_target < 0) return false;
            var _stasis_ok = trait_Execute(_trait, trait_CreateStasisContext(_trait.dot_type, _trait.amount, _trait.duration, "player", _stasis_target));
            if (_stasis_ok) {
                battle_EnemyLog_Write("Turn " + string(battle_EnemyLog_GetTurn())
                    + " | " + _monster.name + " (slot " + string(_enemy_slot_index) + ")"
                    + " | ABILITY stasis " + _trait.dot_type + " -> player slot " + string(_stasis_target));
            }
            return _stasis_ok;

        default:
            battle_EnemyLog_Skipped(_enemy_slot_index, _monster, "effect not implemented: " + _trait.type);
            show_debug_message(_monster.name + " effect pending: " + _trait.type);
            return false;
    }
}

function battle_EnemyUseAllEffects(_enemy_slot_index, _monster) {
    if (status_IsSilenced(_monster)) return false;

    var _traits = trait_GetFromMonster(_monster);
    var _used = false;

    for (var i = 0; i < array_length(_traits); i++) {
        var _type = _traits[i].type;
        if (_type == "none" || _type == "attack") continue;
        if (battle_EnemyUseEffectTrait(_enemy_slot_index, _monster, _traits[i])) _used = true;
    }

    return _used;
}

function battle_EnemyAttack(_enemy_slot_index, _monster) {
    var _target = battle_PickRandomPlayerMonsterSlot();
    if (_target < 0) {
        battle_EnemyLog_Skipped(_enemy_slot_index, _monster, "no player target");
        show_debug_message(_monster.name + " has no player target");
        return false;
    }

    var _ctx = trait_CreateAttackContext(_monster.attack, "player", _target);
    var _ok = trait_ExecuteAttack(_ctx);
    if (_ok) {
        battle_EnemyLog_Attack(_enemy_slot_index, _monster, _target, _monster.attack);
        show_debug_message(_monster.name + " attacked player slot " + string(_target)
            + " for " + string(_monster.attack));
    }
    return _ok;
}

function battle_EnemyTakeTurn(_enemy_slot_index, _monster) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone
        && _enemy_slot_index >= 0
        && _enemy_slot_index < array_length(_board.enemy_slots)) {
        var _live_slot = _board.enemy_slots[_enemy_slot_index];
        if (_live_slot.occupied && _live_slot.card != undefined) {
            _monster = _live_slot.card;
        }
    }

    if (_monster == undefined || !_monster.alive) return;

    if (status_IsSilenced(_monster)) {
        battle_EnemyLog_Skipped(_enemy_slot_index, _monster, "silenced — skipped turn");
        show_debug_message(_monster.name + " is silenced and skips this enemy phase");
        return;
    }

    if (monster_IsElite(_monster)) {
        battle_EnemyUseAllEffects(_enemy_slot_index, _monster);
        battle_EnemyAttack(_enemy_slot_index, _monster);
        return;
    }

    if (battle_EnemyHasEffect(_monster)) {
        battle_EnemyUseAllEffects(_enemy_slot_index, _monster);
    } else {
        battle_EnemyAttack(_enemy_slot_index, _monster);
    }
}

function battle_RunEnemyTurn() {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return;

    status_TickEnemyDoTs(_board, _mm);

    battle_EnemyLog_Write("--- Enemy phase (player turn " + string(battle_EnemyLog_GetTurn()) + " ended) ---");

    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;
        battle_EnemyTakeTurn(i, _slot.card);
        status_TickSilence(_slot.card);
    }
}
