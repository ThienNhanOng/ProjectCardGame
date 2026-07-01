/// @desc Shared state, trait helpers, and enemy targeting for monster abilities

#macro MONSTER_ABILITY_LOG_MAX 10

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

function monsterAbility_LogActivated(_monster, _trait) {
    battle_EnemyLog_Action(_monster.name + " activated " + monsterAbility_GetDisplayName(_trait) + ".");
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

function monsterAbility_GetCardIdPool(_trait) {
    if (_trait == undefined) return [];
    if (variable_struct_exists(_trait, "card_ids") && is_array(_trait.card_ids)) {
        return _trait.card_ids;
    }
    if (variable_struct_exists(_trait, "ids") && is_array(_trait.ids)) {
        return _trait.ids;
    }
    if (_trait.card_id > 0) return [_trait.card_id];
    return [];
}

function monsterAbility_PickCardIdFromPool(_trait, _pool) {
    if (array_length(_pool) > 0) {
        return floor(_pool[irandom(array_length(_pool) - 1)]);
    }
    if (_trait != undefined && _trait.card_id > 0) return _trait.card_id;
    return -1;
}

function monsterAbility_BuildQueueEntry(_source_monster, _trait) {
    if (_trait == undefined || _source_monster == undefined) return undefined;

    var _enemy_id = -1;
    if (variable_struct_exists(_trait, "enemy_id") && _trait.enemy_id >= 0) {
        _enemy_id = floor(_trait.enemy_id);
    }
    if (_enemy_id < 0) return undefined;

    var _collection = _source_monster.collection;
    if (variable_struct_exists(_trait, "collection") && string(_trait.collection) != "") {
        _collection = monster_NormalizeCollectionName(_trait.collection);
    }

    return { collection: _collection, enemyID: _enemy_id };
}
