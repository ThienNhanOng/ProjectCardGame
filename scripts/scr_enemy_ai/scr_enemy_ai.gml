/// @desc Enemy AI — decides WHAT an enemy monster does and WHO it targets.
/// Executing the chosen ability is shared with the player (scr_enemy_abilities -> trait_Execute / card_*).
///
/// Each enemy cycles through its ability list, one ability per enemy turn. Abilities with a
/// "delay" count down first ("2 enemy turns remaining until ... activates").

#macro MONSTER_ABILITY_LOG_MAX 10

// ---------------------------------------------------------------------------
// Per-monster ability state
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Ability cycle
// ---------------------------------------------------------------------------

/// "none" and "attack" are passive — the monster just makes its normal attack
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

/// Ability step of an enemy's turn: fire a delayed ability that is ready, start a new delay,
/// or use the current ability right away.
function monsterAbility_TryActivateStep(_slot_index, _monster) {
    monsterAbility_InitState(_monster);
    if (status_IsSilenced(_monster)) return;

    if (_monster.pending_delayed != undefined) {
        if (_monster.pending_delayed.countdown <= 0) {
            var _pending_trait = _monster.pending_delayed.trait;
            _monster.pending_delayed = undefined;
            monsterAbility_ActivateTrait(_slot_index, _monster, _pending_trait);
            if (!monsterAbility_Picker_IsActive()) {
                monsterAbility_TryRestartDelayed(_slot_index, _monster, _pending_trait);
            }
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

// ---------------------------------------------------------------------------
// Delayed abilities
// ---------------------------------------------------------------------------

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

function monsterAbility_TickDelayedCountdown(_monster) {
    if (_monster == undefined || _monster.pending_delayed == undefined) return;
    if (_monster.pending_delayed.countdown > 0) {
        _monster.pending_delayed.countdown--;
    }
}

/// Delayed discards start counting down again after they fire
function monsterAbility_ShouldRepeatDelayed(_trait) {
    if (_trait == undefined) return false;
    if (monsterAbility_GetDelay(_trait) <= 0) return false;
    return _trait.type == "discard_hand" || _trait.type == "discard_extra_deck";
}

function monsterAbility_TryRestartDelayed(_slot_index, _monster, _trait) {
    if (_monster == undefined || _trait == undefined || !_monster.alive) return;
    if (!monsterAbility_ShouldRepeatDelayed(_trait)) return;
    if (_monster.pending_delayed != undefined) return;
    if (status_IsSilenced(_monster)) return;
    monsterAbility_StartDelayed(_slot_index, _monster, _trait);
}

// ---------------------------------------------------------------------------
// Target choices
// ---------------------------------------------------------------------------

/// Heal: the ally with the lowest health ratio (ties keep the earlier slot)
function monsterAbility_PickHealTarget(_preferred_slot) {
    var _best = _preferred_slot;
    var _best_ratio = 1;

    var _slots = unit_GetAliveSlots(SIDE_ENEMY);
    for (var i = 0; i < array_length(_slots); i++) {
        var _card = unit_Get(SIDE_ENEMY, _slots[i]);
        var _ratio = (_card.max_health > 0) ? _card.health / _card.max_health : 0;
        if (_ratio < _best_ratio) {
            _best_ratio = _ratio;
            _best = _slots[i];
        }
    }
    return _best;
}

/// Buff: the ally with the lowest attack
function monsterAbility_PickBuffTarget(_source_slot) {
    var _best = _source_slot;
    var _best_atk = infinity;

    var _slots = unit_GetAliveSlots(SIDE_ENEMY);
    for (var i = 0; i < array_length(_slots); i++) {
        var _card = unit_Get(SIDE_ENEMY, _slots[i]);
        if (_card.attack < _best_atk) {
            _best_atk = _card.attack;
            _best = _slots[i];
        }
    }
    return _best;
}

/// Targets an enemy chooses for a unit effect, following the trait's target rule.
/// ("ally" = another enemy monster, "enemy" = the player's monsters.)
///   self          the caster
///   single_ally   heal: the most hurt ally; buff: the weakest ally; otherwise a random ally
///   single_any    enemies always help their own side (same as single_ally)
///   single_enemy  a random player monster
///   all_allies / all_enemies   everyone on that side (an empty player board means the player)
function monsterAbility_PickTargets(_slot_index, _monster, _trait) {
    var _src = effect_Source(SIDE_ENEMY, _slot_index);

    switch (_trait.target) {
        case "self":
            return targets_Single(SIDE_ENEMY, _slot_index);

        case "single_ally":
        case "single_any":
            if (_trait.effect == "heal") return targets_Single(SIDE_ENEMY, monsterAbility_PickHealTarget(_slot_index));
            if (_trait.effect == "buff") return targets_Single(SIDE_ENEMY, monsterAbility_PickBuffTarget(_slot_index));
            var _ally = unit_PickRandom(SIDE_ENEMY);
            return (_ally < 0) ? [] : targets_Single(SIDE_ENEMY, _ally);

        case "single_enemy":
            var _victim = monsterAbility_PickPlayerTarget(_trait, _monster);
            return (_victim < 0) ? [] : targets_Single(SIDE_PLAYER, _victim);

        case "all_allies":
            return targets_AllAllies(_src);

        case "all_enemies":
            return targets_AllOpponents(_src);
    }
    return [];
}

// ---------------------------------------------------------------------------
// Choosing which player monster to hit
// ---------------------------------------------------------------------------

#macro AI_TARGET_JITTER 12        // random 0..N added to each score so the AI is not perfectly predictable

/// How dangerous a player monster is (its attack, less if it cannot attack right now / is about to leave)
function monsterAbility_ThreatOf(_card, _slot) {
    var _atk = max(0, battle_GetPlayerMonsterSummaryAttack(_card, _slot));
    if (status_IsShrouded(_card)) _atk *= 0.3;                          // cannot attack anyway
    if (variable_struct_exists(_card, "board_expire") && _card.board_expire
        && variable_struct_exists(_card, "board_turns_left") && _card.board_turns_left == 1) _atk *= 0.5;   // leaving soon
    return _atk;
}

/// Score for hitting this player monster with _damage: a kill beats everything (more for strong monsters and
/// for overflow damage that spills onto the player); otherwise chip the biggest threat.
function monsterAbility_ScoreAttackTarget(_slot, _damage) {
    var _card = unit_Get(SIDE_PLAYER, _slot);
    if (_card == undefined) return -infinity;
    battle_EnsureCardHealth(_card);
    var _hp = max(1, _card.health);
    var _threat = monsterAbility_ThreatOf(_card, _slot);
    if (_damage >= _hp) {
        var _overflow = card_IsSpiritType(_card) ? 0 : (_damage - _hp);
        return 100 + _threat * 6 + _overflow * 3;
    }
    return 40 * (_damage / _hp) + _threat * 4;
}

/// The player monster an enemy should attack for _damage (-1 when the player has none).
/// Back-row monsters guarded by a frontline are skipped.
function monsterAbility_PickAttackTarget(_damage) {
    var _slots = unit_GetDamageableSlots(SIDE_PLAYER);
    var _best = -1;
    var _best_score = -infinity;
    for (var i = 0; i < array_length(_slots); i++) {
        var _score = monsterAbility_ScoreAttackTarget(_slots[i], _damage) + random(AI_TARGET_JITTER);
        if (_score > _best_score) {
            _best_score = _score;
            _best = _slots[i];
        }
    }
    return _best;
}

/// Hostile single-target abilities: destroy / silence / shroud the most dangerous monster,
/// damage effects use the attack scoring, anything else picks at random.
function monsterAbility_PickPlayerTarget(_trait = undefined, _monster = undefined) {
    var _slots = unit_GetAliveSlots(SIDE_PLAYER);
    if (array_length(_slots) <= 0) return -1;
    var _effect = (_trait != undefined && variable_struct_exists(_trait, "effect")) ? _trait.effect : "";
    if (_effect == "damage") return monsterAbility_PickAttackTarget(max(0, _trait.amount));

    var _best = -1;
    var _best_score = -infinity;
    for (var i = 0; i < array_length(_slots); i++) {
        var _card = unit_Get(SIDE_PLAYER, _slots[i]);
        battle_EnsureCardHealth(_card);
        var _score;
        switch (_effect) {
            case "destroy":
                _score = monsterAbility_ThreatOf(_card, _slots[i]) * 3 + _card.health;
                break;
            case "silence":
                _score = array_length(trait_GetFromCard(_card)) * 10 + monsterAbility_ThreatOf(_card, _slots[i]) * 2;
                if (status_IsSilenced(_card)) _score -= 1000;           // already silenced
                break;
            case "shroud":
                _score = monsterAbility_ThreatOf(_card, _slots[i]) * 3;
                if (status_IsShrouded(_card)) _score -= 1000;           // already cannot attack
                break;
            default:
                _score = 0;
                break;
        }
        _score += random(AI_TARGET_JITTER);
        if (_score > _best_score) {
            _best_score = _score;
            _best = _slots[i];
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

/// Wave-queue entry for summon_enemy (defaults to the summoner's own collection)
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
