/// @desc Enemy abilities — run the ability scr_enemy_ai chose, through the same trait engine as player cards.
///
/// Unit effects (heal, damage, silence, shroud, destroy, buffs …) pick targets with
/// monsterAbility_PickTargets (the trait's target rule) and run through trait_Execute — the same code
/// player cards use. Only behaviour that exists solely for enemies lives here:
///   attack_all  = the next N attacks hit every player monster (charges)
///   buffs       = timed (wear off after "turns")
///   destroy     = "amount" random player monsters
///   summon_enemy = "to": "board" (a free spot now) or "queue" (the front of the wave queue)
///   discard_hand / discard_extra_deck / add_deck

/// Use an ability now and write it to the battle log
function monsterAbility_ActivateTrait(_slot_index, _monster, _trait) {
    if (_trait == undefined || _monster == undefined) return false;
    if (status_IsSilenced(_monster)) return false;

    if (_trait.type == "attack_all" || _trait.effect == "buff") {
        var _ok = monsterAbility_RunEffect(_slot_index, _monster, _trait);
        if (_ok) {
            monsterAbility_LogActivated(_monster, _trait);
            monsterAnim_PlayAttack(_monster);
        }
        return _ok;
    }

    if (monsterAbility_HasEffect(_trait)) {
        var _used = monsterAbility_RunEffect(_slot_index, _monster, _trait);
        if (_used) monsterAnim_PlayAttack(_monster);   // casting uses the attack animation too
        return _used;
    }

    // unknown types with a delay still announce themselves when the delay ends
    if (monsterAbility_GetDelay(_trait) > 0) {
        monsterAbility_LogActivated(_monster, _trait);
        return true;
    }
    return false;
}

/// Can an enemy use this trait? Any shared unit effect, plus the enemy-only abilities.
function monsterAbility_HasEffect(_trait) {
    switch (_trait.type) {
        case "attack_all":
        case "discard_hand":
        case "discard_extra_deck":
        case "add_deck":
        case "summon_enemy":
            return true;
    }
    return trait_IsUnitEffect(_trait.effect) && _trait.effect != "attack";
}

/// Perform an ability's effect. attack_all and buffs do not log here (the caller does).
function monsterAbility_RunEffect(_slot_index, _monster, _trait) {
    var _src = effect_Source(SIDE_ENEMY, _slot_index);

    switch (_trait.type) {
        case "attack_all":
            // the next N attacks of this monster hit every player monster
            monsterAbility_InitState(_monster);
            _monster.attack_all_charges = max(0, floor(max(1, _trait.amount)));
            return true;

        case "discard_hand":
            return monsterAbility_BeginDiscardHand(_slot_index, _monster, _trait);

        case "discard_extra_deck":
            return monsterAbility_BeginDiscardExtraDeck(_slot_index, _monster, _trait);

        case "add_deck":
            return monsterAbility_AddCardsToPlayerDeck(_src, _monster, _trait);

        case "summon_enemy":
            // "to": "board" (default) = into a free spot now; "queue" = waits in the wave queue
            var _entry = monsterAbility_BuildQueueEntry(_monster, _trait);
            if (_entry == undefined) return false;
            var _went = monster_Summon(_entry, _trait.summon_to);
            if (_went == "") return false;
            monsterAbility_LogActivated(_monster, _trait);
            if (_went == "queue" && _trait.summon_to == "board") {
                battle_EnemyLog_Action("No room on the field: it waits in the queue.");
            }
            return true;
    }

    // enemy buffs wear off after "turns" enemy turns
    if (_trait.effect == "buff") {
        if (_trait.amount <= 0) return false;
        var _buff_targets = monsterAbility_PickTargets(_slot_index, _monster, _trait);
        var _source_name = (_trait.target == "self") ? "" : _monster.name;
        var _buffed = false;
        for (var b = 0; b < array_length(_buff_targets); b++) {
            if (_buff_targets[b].side != SIDE_ENEMY) continue;
            if (monsterAbility_BuffWithTimer(_src, _buff_targets[b].slot, _trait.amount, monsterAbility_GetBuffTurns(_trait), _source_name)) {
                _buffed = true;
            }
        }
        return _buffed;
    }

    // enemy destroy removes "amount" random player monsters, one pick at a time
    if (_trait.effect == "destroy" && _trait.target == "single_enemy") {
        var _destroyed = 0;
        var _count = max(1, _trait.amount);
        for (var n = 0; n < _count; n++) {
            if (battle_IsPlayerDefeated()) break;
            var _target = monsterAbility_PickPlayerTarget(_trait, _monster);
            if (_target < 0) break;
            if (trait_Execute(_trait, trait_CreateContext(_src, targets_Single(SIDE_PLAYER, _target)))) _destroyed++;
        }
        if (_destroyed > 0) monsterAbility_LogActivated(_monster, _trait);
        return _destroyed > 0;
    }

    // every other shared unit effect: AI picks targets, the trait engine applies it
    if (trait_IsUnitEffect(_trait.effect) && _trait.effect != "attack") {
        var _targets = monsterAbility_PickTargets(_slot_index, _monster, _trait);
        if (array_length(_targets) <= 0) return false;
        var _done = trait_Execute(_trait, trait_CreateContext(_src, _targets));
        if (_done) monsterAbility_LogActivated(_monster, _trait);
        return _done;
    }
    return false;
}

// ---------------------------------------------------------------------------
// Enemy-only effects
// ---------------------------------------------------------------------------

/// +attack on an enemy that wears off after _turns enemy turns
function monsterAbility_BuffWithTimer(_src, _target_slot, _amount, _turns, _source_name) {
    if (_amount <= 0) return false;
    if (!card_BuffAttack(_src, targets_Single(SIDE_ENEMY, _target_slot), _amount)) return false;

    var _unit = unit_Get(SIDE_ENEMY, _target_slot);
    status_Apply(_unit, STATUS_TIMED_ATTACK_BUFF, _turns, { amount: _amount, source_name: _source_name });
    return true;
}

/// Normal attack step of an enemy's turn (single target, or everything while attack_all charges last)
function monsterAbility_PerformAttack(_slot_index, _monster) {
    if (_monster == undefined || !_monster.alive || battle_IsPlayerDefeated()) return false;

    monsterAbility_InitState(_monster);
    var _src = effect_Source(SIDE_ENEMY, _slot_index);
    var _damage = max(0, _monster.attack);

    if (_monster.attack_all_charges > 0) {
        var _all = targets_AllOpponents(_src);
        if (_damage > 0) battlefx_EnemyAttack(_slot_index, _all);   // arrows, then the attack animation, then the hits
        var _hit_all = card_Damage(_src, _all, _damage);
        battlefx_EndDelay();
        if (_hit_all) {
            battle_EnemyLog_Action(_monster.name + " attacks all for " + string(_damage) + " damage.");
            _monster.attack_all_charges--;
        }
        return _hit_all;
    }

    var _player_target = monsterAbility_PickAttackTarget(_damage);
    var _targets = targets_AttackDefender(SIDE_PLAYER, _player_target);
    if (_damage > 0) battlefx_EnemyAttack(_slot_index, _targets);   // arrow, then the attack animation, then the hit
    var _hit = card_Damage(_src, _targets, _damage);
    battlefx_EndDelay();
    if (_hit) {
        battle_EnemyLog_Action(_monster.name + " attacks for " + string(_damage) + " damage.");
    }
    return _hit;
}

/// Player must choose card(s) to discard from hand (optionally only one card type).
/// Only cards that match the filter count, so the player can always finish the choice.
function monsterAbility_BeginDiscardHand(_slot_index, _monster, _trait) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone || _hand.hand_Count <= 0) return false;

    var _filter = variable_struct_exists(_trait, "hand_filter") ? _trait.hand_filter : "";
    var _matching = (_filter == "") ? _hand.hand_Count : conditions_CountHandCards({ types: [_filter] });
    if (_matching <= 0) return false;

    var _count = min(max(1, _trait.amount), _matching);
    var _prompt = _monster.name + " — choose " + string(_count) + " card(s) to discard";

    monsterAbility_LogActivated(_monster, _trait);

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) monsterAbility_Picker_Begin("discard_hand", _count, _prompt, _filter, _slot_index, _trait);
    return true;
}

/// Player must choose spirit card(s) to discard from the extra deck
function monsterAbility_BeginDiscardExtraDeck(_slot_index, _monster, _trait) {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone || _deck.extra_deck_Count <= 0) return false;

    var _count = min(max(1, _trait.amount), _deck.extra_deck_Count);
    var _prompt = _monster.name + " — choose " + string(_count) + " extra deck card(s) to discard";

    monsterAbility_LogActivated(_monster, _trait);

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) monsterAbility_Picker_Begin("discard_extra_deck", _count, _prompt, "", _slot_index, _trait);
    return true;
}

/// add_deck — shuffle card(s) into the player's deck (fixed id or random pick from card_ids)
function monsterAbility_AddCardsToPlayerDeck(_src, _monster, _trait) {
    var _pool = monsterAbility_GetCardIdPool(_trait);
    var _times = max(1, _trait.amount);
    var _added = false;

    for (var i = 0; i < _times; i++) {
        var _id = monsterAbility_PickCardIdFromPool(_trait, _pool);
        if (_id <= 0) continue;
        if (card_AddCard(_src, "deck", _id)) _added = true;
    }

    if (_added) monsterAbility_LogActivated(_monster, _trait);
    return _added;
}
