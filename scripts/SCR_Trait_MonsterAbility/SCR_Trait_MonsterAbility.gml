/// @desc Enemy monster ability implementations (scripts/cardcollection/Traits/monsterAbility)

#macro MONSTER_ABILITY_LOG_MAX 50

function monsterAbility_InitState(_monster) {
    if (_monster == undefined) return;
    if (!variable_struct_exists(_monster, "ability_index")) _monster.ability_index = 0;
    if (!variable_struct_exists(_monster, "pending_delayed")) _monster.pending_delayed = undefined;
    if (!variable_struct_exists(_monster, "attack_all_charges")) _monster.attack_all_charges = 0;
    if (!variable_struct_exists(_monster, "timed_attack_buffs")) _monster.timed_attack_buffs = [];
}

function monsterAbility_ClearPending(_monster) {
    if (_monster == undefined) return;
    _monster.pending_delayed = undefined;
}

function monsterAbility_OnDeath(_monster) {
    monsterAbility_ClearPending(_monster);
    if (_monster == undefined) return;
    _monster.attack_all_charges = 0;
}

function monsterAbility_GetDelay(_trait) {
    if (_trait == undefined) return 0;
    if (variable_struct_exists(_trait, "delay")) return max(0, floor(_trait.delay));
    return 0;
}

function monsterAbility_GetBuffTurns(_trait) {
    if (_trait == undefined) return 1;
    if (_trait.type != "self_buff" && _trait.type != "buff") return 0;
    if (variable_struct_exists(_trait, "buff_turns") && _trait.buff_turns > 0) {
        return max(1, floor(_trait.buff_turns));
    }
    if (variable_struct_exists(_trait, "turns")) return max(1, floor(_trait.turns));
    return 1;
}

function monsterAbility_GetDisplayName(_trait) {
    if (_trait == undefined) return "ability";
    if (variable_struct_exists(_trait, "name") && string(_trait.name) != "") {
        return string(_trait.name);
    }
    return trait_GetDisplayText(_trait);
}

function monsterAbility_IsPassiveType(_type) {
    return _type == "none" || _type == "attack";
}

function monsterAbility_GetCurrentTrait(_monster) {
    var _traits = trait_GetFromMonster(_monster);
    if (array_length(_traits) <= 0) return undefined;

    var _index = _monster.ability_index mod array_length(_traits);
    return _traits[_index];
}

function monsterAbility_AdvanceCycle(_monster) {
    var _traits = trait_GetFromMonster(_monster);
    if (array_length(_traits) <= 0) return;
    _monster.ability_index = (_monster.ability_index + 1) mod array_length(_traits);
}

function monsterAbility_LogCountdown(_slot_index, _monster) {
    if (_monster.pending_delayed == undefined) return;
    var _countdown = _monster.pending_delayed.countdown;
    if (_countdown <= 0) return;

    var _name = _monster.pending_delayed.display_name;
    var _turn_word = (_countdown == 1) ? "turn" : "turns";
    battle_EnemyLog_Action(_monster.name + ": " + string(_countdown)
        + " enemy " + _turn_word + " remaining until " + _name + " activates.");
}

function monsterAbility_StartDelayed(_slot_index, _monster, _trait) {
    var _delay = monsterAbility_GetDelay(_trait);
    if (_delay <= 0) return false;

    _monster.pending_delayed = {
        trait: _trait,
        countdown: _delay,
        display_name: monsterAbility_GetDisplayName(_trait)
    };
    return true;
}

function monsterAbility_ActivateTrait(_slot_index, _monster, _trait) {
    if (_trait == undefined || _monster == undefined) return false;
    if (status_IsSilenced(_monster)) return false;

    var _name = monsterAbility_GetDisplayName(_trait);

    switch (_trait.type) {
        case "attack_all":
            monsterAbility_attack_all(_slot_index, _monster, max(1, _trait.amount));
            battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
            return true;

        case "self_buff":
            monsterAbility_self_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
            battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
            return true;

        case "buff":
            monsterAbility_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
            battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
            return true;

        case "destroy":
            monsterAbility_destroy(_slot_index, _monster, max(1, _trait.amount));
            battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
            return true;

        case "heal":
            var _heal_target = battle_EnemyPickHealTarget(_slot_index);
            var _heal_ok = trait_Execute(_trait, trait_CreateHealContext(_trait.amount, "enemy", _heal_target));
            if (_heal_ok) battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
            return _heal_ok;

        case "heal_all":
            var _heal_all_ok = trait_Execute(_trait, trait_CreateHealAllContext(_trait.amount, "enemy"));
            if (_heal_all_ok) battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
            return _heal_all_ok;

        case "silence":
            var _silence_target = battle_PickRandomPlayerMonsterSlot();
            if (_silence_target < 0) return false;
            var _silence_ok = trait_Execute(_trait, trait_CreateSilenceContext(max(1, _trait.amount), "player", _silence_target));
            if (_silence_ok) battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
            return _silence_ok;

        default:
            if (monsterAbility_GetDelay(_trait) > 0) {
                monsterAbility_ApplyDelayedEffect(_slot_index, _monster, _trait);
                battle_EnemyLog_Action(_monster.name + " activated " + _name + ".");
                return true;
            }
            show_debug_message(_monster.name + " ability pending: " + string(_trait.type));
            return false;
    }
}

function monsterAbility_ApplyDelayedEffect(_slot_index, _monster, _trait) {
    switch (_trait.type) {
        case "attack_all":
            monsterAbility_attack_all(_slot_index, _monster, max(1, _trait.amount));
            break;
        case "self_buff":
            monsterAbility_self_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
            break;
        case "buff":
            monsterAbility_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
            break;
        case "destroy":
            monsterAbility_destroy(_slot_index, _monster, max(1, _trait.amount));
            break;
        default:
            show_debug_message(_monster.name + " delayed effect: " + string(_trait.type));
            break;
    }
}

function monsterAbility_TryActivateStep(_slot_index, _monster) {
    monsterAbility_InitState(_monster);
    if (status_IsSilenced(_monster)) return;

    if (_monster.pending_delayed != undefined) {
        if (_monster.pending_delayed.countdown <= 0) {
            var _pending_trait = _monster.pending_delayed.trait;
            _monster.pending_delayed = undefined;
            monsterAbility_ActivateTrait(_slot_index, _monster, _pending_trait);
        }
        return;
    }

    var _trait = monsterAbility_GetCurrentTrait(_monster);
    if (_trait == undefined || monsterAbility_IsPassiveType(_trait.type)) return;

    if (monsterAbility_GetDelay(_trait) > 0) {
        monsterAbility_StartDelayed(_slot_index, _monster, _trait);
        return;
    }

    monsterAbility_ActivateTrait(_slot_index, _monster, _trait);
}

function monsterAbility_TickDelayedCountdown(_monster) {
    if (_monster == undefined || _monster.pending_delayed == undefined) return;
    if (_monster.pending_delayed.countdown > 0) {
        _monster.pending_delayed.countdown--;
    }
}

/// Sets up attack_all for the next N attacks (current attack remains single-target).
function monsterAbility_attack_all(_slot_index, _monster, _attack_count) {
    monsterAbility_InitState(_monster);
    _monster.attack_all_charges = max(0, floor(_attack_count));
}

function monsterAbility_self_buff(_slot_index, _monster, _amount, _turns) {
    if (_amount <= 0) return false;

    if (!battle_BuffEnemyMonster(_slot_index, _amount)) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return true;
    var _target_card = _board.enemy_slots[_slot_index].card;
    monsterAbility_ApplyTimedBuff(_target_card, _amount, _turns);
    return true;
}

function monsterAbility_buff(_slot_index, _monster, _amount, _turns) {
    if (_amount <= 0) return false;

    var _ally = battle_EnemyPickBuffAllyTarget(_slot_index);
    if (_ally < 0) return false;
    if (!battle_BuffEnemyMonster(_ally, _amount)) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return true;
    var _target_card = _board.enemy_slots[_ally].card;
    monsterAbility_ApplyTimedBuff(_target_card, _amount, _turns);
    return true;
}

function monsterAbility_ApplyTimedBuff(_card, _amount, _turns) {
    if (_card == undefined || _amount <= 0 || _turns <= 0) return;
    monsterAbility_InitTimedBuffs(_card);
    array_push(_card.timed_attack_buffs, { amount: _amount, turns_left: _turns });
}

function monsterAbility_InitTimedBuffs(_card) {
    if (_card == undefined) return;
    if (!variable_struct_exists(_card, "timed_attack_buffs") || !is_array(_card.timed_attack_buffs)) {
        _card.timed_attack_buffs = [];
    }
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

function monsterAbility_destroy(_slot_index, _monster, _target_count) {
    var _destroyed = 0;
    for (var n = 0; n < _target_count; n++) {
        if (battle_IsPlayerDefeated()) break;
        var _target = battle_PickRandomPlayerMonsterSlot();
        if (_target < 0) break;
        if (trait_Execute({ type: "destroy", amount: 1 },
            trait_CreateDestroyContext(1, "player", _target))) {
            _destroyed++;
        }
    }
    return _destroyed > 0;
}

function monsterAbility_PerformAttack(_slot_index, _monster) {
    if (_monster == undefined || !_monster.alive || battle_IsPlayerDefeated()) return false;

    monsterAbility_InitState(_monster);
    var _damage = max(0, _monster.attack);

    if (_monster.attack_all_charges > 0) {
        var _ok = trait_ExecuteAttackAll(trait_CreateAttackAllContext(_damage, "player"));
        if (_ok) {
            battle_EnemyLog_Action(_monster.name + " attacks all for " + string(_damage) + " damage.");
            _monster.attack_all_charges--;
        }
        return _ok;
    }

    var _player_target = battle_PickRandomPlayerMonsterSlot();
    var _ctx = trait_CreateAttackContext(_damage, "player", _player_target);
    var _ok = trait_ExecuteAttack(_ctx);
    if (_ok) {
        battle_EnemyLog_Action(_monster.name + " attacks for " + string(_damage) + " damage.");
    }
    return _ok;
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
    return battle_EnemyPickBuffAllyTarget(_source_slot);
}

function battle_EnemyPickBuffAllyTarget(_source_slot) {
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
