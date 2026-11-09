/// @desc Units and targets — one way to address monsters for BOTH sides.
///
/// A "unit" is a monster card standing in a board slot. Every unit is addressed by a side
/// ("player" or "enemy") and a slot index, so effects never need separate player/enemy code:
///
///     card_Heal(_source, targets_Single("player", 2), 5);   // heal one player monster
///     card_Heal(_source, targets_AllAllies(_source), 5);    // heal every ally of the source
///     card_Damage(_source, targets_AllOpponents(_source), 3);
///
/// The player's own life total can be targeted as slot UNIT_HERO on the "player" side.

#macro SIDE_PLAYER "player"
#macro SIDE_ENEMY "enemy"
#macro UNIT_HERO -1

// ---------------------------------------------------------------------------
// References
// ---------------------------------------------------------------------------

function unit_Ref(_side, _slot) {
    return { side: _side, slot: _slot };
}

/// Who is acting. _slot is the source board slot (-1 for action cards / no slot).
function effect_Source(_side, _slot = -1) {
    return { side: _side, slot: _slot };
}

function unit_OpposingSide(_side) {
    return (_side == SIDE_PLAYER) ? SIDE_ENEMY : SIDE_PLAYER;
}

// ---------------------------------------------------------------------------
// Board access
// ---------------------------------------------------------------------------

/// Number of slots that can hold units (enemy side: only the active wave slots)
function unit_GetSlotCount(_side) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    if (_side == SIDE_PLAYER) return array_length(_board.player_monster_slots);

    if (_side == SIDE_ENEMY) {
        var _mm = instance_find(OBJ_MonsterManager, 0);
        if (_mm == noone) return 0;
        return min(_mm.active_slot_count, array_length(_board.enemy_slots));
    }
    return 0;
}

/// Board slot struct for a unit position, or undefined when out of range
function unit_GetBoardSlot(_side, _slot) {
    if (_slot < 0 || _slot >= unit_GetSlotCount(_side)) return undefined;
    var _board = instance_find(OBJ_BoardManager, 0);
    return (_side == SIDE_PLAYER) ? _board.player_monster_slots[_slot] : _board.enemy_slots[_slot];
}

/// The living unit card at a position, or undefined
function unit_Get(_side, _slot) {
    var _bslot = unit_GetBoardSlot(_side, _slot);
    if (_bslot == undefined) return undefined;
    if (!_bslot.visible || !_bslot.occupied || _bslot.card == undefined) return undefined;
    if (_side == SIDE_ENEMY && !_bslot.card.alive) return undefined;
    return _bslot.card;
}

function unit_IsAlive(_side, _slot) {
    return unit_Get(_side, _slot) != undefined;
}

/// Slot indices of every living unit on a side, in board order
function unit_GetAliveSlots(_side) {
    var _slots = [];
    var _count = unit_GetSlotCount(_side);
    for (var i = 0; i < _count; i++) {
        if (unit_IsAlive(_side, i)) array_push(_slots, i);
    }
    return _slots;
}

function unit_Count(_side) {
    return array_length(unit_GetAliveSlots(_side));
}

/// Random living unit slot on a side, or -1 when there is none
function unit_PickRandom(_side) {
    var _choices = unit_GetAliveSlots(_side);
    if (array_length(_choices) == 0) return -1;
    return _choices[irandom(array_length(_choices) - 1)];
}

/// Slot index holding a specific card struct, or -1
function unit_FindSlotOfCard(_side, _card) {
    if (_card == undefined) return -1;
    var _count = unit_GetSlotCount(_side);
    for (var i = 0; i < _count; i++) {
        var _bslot = unit_GetBoardSlot(_side, i);
        if (_bslot.occupied && _bslot.card == _card) return i;
    }
    return -1;
}

/// Unit under a point (player side: slot rectangle, enemy side: monster hitbox). -1 when none.
function unit_GetSlotAt(_side, _mx, _my) {
    var _count = unit_GetSlotCount(_side);
    for (var i = 0; i < _count; i++) {
        if (!unit_IsAlive(_side, i)) continue;
        var _bslot = unit_GetBoardSlot(_side, i);
        if (_side == SIDE_ENEMY) {
            if (monster_IsMouseOverSlot(_bslot)) return i;
        } else if (point_in_rectangle(_mx, _my, _bslot.x, _bslot.y, _bslot.x + _bslot.w, _bslot.y + _bslot.h)) {
            return i;
        }
    }
    return -1;
}

// ---------------------------------------------------------------------------
// Target lists (arrays of unit refs)
// ---------------------------------------------------------------------------

function targets_Single(_side, _slot) {
    return [unit_Ref(_side, _slot)];
}

function targets_All(_side) {
    var _targets = [];
    var _slots = unit_GetAliveSlots(_side);
    for (var i = 0; i < array_length(_slots); i++) {
        array_push(_targets, unit_Ref(_side, _slots[i]));
    }
    return _targets;
}

function targets_AllAllies(_source) {
    return targets_All(_source.side);
}

/// Every opposing unit. Attacks that find an empty player board hit the player instead.
function targets_AllOpponents(_source) {
    var _side = unit_OpposingSide(_source.side);
    var _targets = targets_All(_side);
    if (array_length(_targets) == 0 && _side == SIDE_PLAYER) {
        array_push(_targets, unit_Ref(SIDE_PLAYER, UNIT_HERO));
    }
    return _targets;
}

/// Defender for a single attack. Player side: the chosen monster if it is still there,
/// otherwise a random monster, or the player when the board is empty.
function targets_AttackDefender(_side, _preferred_slot) {
    if (_side != SIDE_PLAYER) return targets_Single(_side, _preferred_slot);

    if (unit_Count(SIDE_PLAYER) <= 0) return targets_Single(SIDE_PLAYER, UNIT_HERO);

    var _target = _preferred_slot;
    if (_target < 0 || !unit_IsAlive(SIDE_PLAYER, _target)) {
        _target = unit_PickRandom(SIDE_PLAYER);
    }
    return targets_Single(SIDE_PLAYER, _target);
}

/// Every living unit on both sides (player units first)
function targets_AnyUnit() {
    var _targets = targets_All(SIDE_PLAYER);
    var _enemies = targets_All(SIDE_ENEMY);
    for (var i = 0; i < array_length(_enemies); i++) array_push(_targets, _enemies[i]);
    return _targets;
}
