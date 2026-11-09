/// @desc Universal card effects — the same functions run for player cards and enemy monsters.
///
/// Every unit effect takes (source, targets, amount):
///   source  = effect_Source(side, slot)            who is acting (player or enemy)
///   targets = array of unit_Ref(side, slot)        one target or many (see scr_card_targeting)
///
///   card_Heal(_src, targets_Single(SIDE_PLAYER, 0), 3);     // heal one
///   card_Heal(_src, targets_AllAllies(_src), 3);            // heal all allies (heal_all)
///   card_Damage(_src, targets_AllOpponents(_src), 2);       // hit every opponent (attack_all)
///
/// Each returns true when at least one target was affected.
/// Deciding WHICH targets to use belongs to the caller (player clicks, or enemy AI in scr_enemy_ai).

// ---------------------------------------------------------------------------
// Unit effects
// ---------------------------------------------------------------------------

function card_Damage(_source, _targets, _amount) {
    if (_amount <= 0) return false;

    var _hit = false;
    for (var i = 0; i < array_length(_targets); i++) {
        if (combat_DamageUnit(_targets[i].side, _targets[i].slot, _amount)) _hit = true;
    }
    return _hit;
}

function card_Heal(_source, _targets, _amount) {
    if (_amount <= 0) return false;

    var _healed = false;
    for (var i = 0; i < array_length(_targets); i++) {
        var _unit = unit_Get(_targets[i].side, _targets[i].slot);
        if (_unit == undefined) continue;
        battle_EnsureCardHealth(_unit);
        _unit.health = min(_unit.max_health, _unit.health + _amount);
        _healed = true;
    }
    return _healed;
}

function card_Destroy(_source, _targets) {
    var _destroyed = false;
    for (var i = 0; i < array_length(_targets); i++) {
        if (combat_RemoveUnit(_targets[i].side, _targets[i].slot)) _destroyed = true;
    }
    return _destroyed;
}

/// Permanent +attack (timed buffs: add status_Apply(_unit, STATUS_TIMED_ATTACK_BUFF, ...) on top)
function card_BuffAttack(_source, _targets, _amount) {
    if (_amount <= 0) return false;

    var _buffed = false;
    for (var i = 0; i < array_length(_targets); i++) {
        var _unit = unit_Get(_targets[i].side, _targets[i].slot);
        if (_unit == undefined) continue;
        card_GainAttack(_unit, _amount);
        _buffed = true;
    }
    return _buffed;
}

/// Silence enemy monsters. A "silence" aimed at a player monster shrouds it instead.
function card_Silence(_source, _targets, _turns) {
    _turns = floor(max(1, real(_turns)));

    var _done = false;
    for (var i = 0; i < array_length(_targets); i++) {
        var _side = _targets[i].side;
        var _slot = _targets[i].slot;
        var _unit = unit_Get(_side, _slot);
        if (_unit == undefined) continue;

        if (_side == SIDE_PLAYER) {
            if (card_Shroud(_source, [_targets[i]], _turns)) _done = true;
            continue;
        }
        if (!status_Apply(_unit, STATUS_SILENCE, _turns)) continue;
        battle_StatusLog_Silence(_side, _slot, _unit.name, _unit.silenced_turns);
        _done = true;
    }
    return _done;
}

/// Shroud player monsters (they cannot attack)
function card_Shroud(_source, _targets, _turns) {
    _turns = floor(max(1, real(_turns)));

    var _done = false;
    for (var i = 0; i < array_length(_targets); i++) {
        var _unit = unit_Get(_targets[i].side, _targets[i].slot);
        if (_unit == undefined) continue;
        if (!status_Apply(_unit, STATUS_SHROUD, _turns)) continue;
        battle_StatusLog_Shroud(_targets[i].slot, _unit.name, _unit.shrouded_turns);
        _done = true;
    }
    return _done;
}

// ---------------------------------------------------------------------------
// Card movement (always the player's hand / deck — enemies can also feed the player's deck)
// ---------------------------------------------------------------------------

function card_DrawCards(_source, _amount) {
    if (_amount <= 0) _amount = 1;

    var _drawn = 0;
    for (var i = 0; i < _amount; i++) {
        if (SCR_Hand_DrawFromDeck()) _drawn++;
        else break;
    }
    return _drawn > 0;
}

/// Add a card (by id) to the player's "hand", "deck" or "extra_deck".
/// Cards added during a play are registered with the trait chain so add_cost can tax them.
function card_AddCard(_source, _zone, _card_id) {
    if (_card_id <= 0) return false;

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;

    var _added = false;
    var _bm = instance_find(OBJ_BattleManager, 0);

    if (_zone == "hand") {
        var _hand = instance_find(OBJ_Hand, 0);
        if (_hand == noone) return false;

        var _card = deck_CreateRuntimeCard(_card_id);
        if (_card == undefined) return false;

        with (_hand) {
            if (hand_IsFull()) return false;
            _added = hand_AddCard(_card);
        }
        if (_added && _bm != noone) {
            with (_bm) trait_ChainRegisterAddedCard(_card);
        }
        return _added;
    }

    with (_deck) {
        _added = (_zone == "extra_deck") ? deck_AddExtraCard(_card_id) : deck_AddCard(_card_id);
    }
    if (_added && _bm != noone) {
        with (_bm) trait_ChainRegisterAddedDeckId(_card_id);
    }
    return _added;
}

/// Zone a card-adding trait type puts its card into
function trait_GetAddCardZone(_type) {
    switch (_type) {
        case "add": return "hand";
        case "add_extra_deck": return "extra_deck";
    }
    return "deck";
}
