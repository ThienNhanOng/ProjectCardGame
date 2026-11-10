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

/// Number of spots on a side (unused / closed spots are hidden; unit_Get skips them)
function unit_GetSlotCount(_side) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    if (_side == SIDE_PLAYER) return array_length(_board.player_monster_slots);

    // every enemy spot (spots this battle doesn't use stay hidden, so unit_Get skips them)
    if (_side == SIDE_ENEMY) return array_length(_board.enemy_slots);
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

// ---------------------------------------------------------------------------
// Depth and the mouse
//
// Units stand on one patch of grass and can overlap (scr_battle_layout). They are drawn far to near
// (higher on screen first), and the unit under the mouse is drawn last of all so it pops out.
// The mouse always picks the top-most unit — the hovered one keeps priority while the mouse stays on it.
// ---------------------------------------------------------------------------

/// Where the unit in this spot stands (feet)
function unit_GetFeet(_side, _slot) {
    return (_side == SIDE_ENEMY) ? battle_LayoutEnemyFeet(_slot) : battle_LayoutPlayerFeet(_slot);
}

/// Spots of a side in drawing order: far to near, with _last (the hovered unit) moved to the very end
function unit_GetDepthOrder(_side, _last = -1) {
    var _count = unit_GetSlotCount(_side);
    var _order = [];
    for (var i = 0; i < _count; i++) {
        if (i == _last) continue;
        var _y = unit_GetFeet(_side, i).y;
        var _pos = array_length(_order);
        while (_pos > 0 && unit_GetFeet(_side, _order[_pos - 1]).y > _y) _pos--;
        array_insert(_order, _pos, i);
    }
    if (_last >= 0 && _last < _count) array_push(_order, _last);
    return _order;
}

/// Is the point on this spot? Your side: the card area. Enemies: body, pedestal and health bar.
function unit_SpotContains(_side, _slot, _mx, _my) {
    var _bslot = unit_GetBoardSlot(_side, _slot);
    if (_bslot == undefined) return false;
    if (_side == SIDE_ENEMY) return monster_IsPointOverSlot(_bslot, _mx, _my);
    return point_in_rectangle(_mx, _my, _bslot.x, _bslot.y, _bslot.x + _bslot.w, _bslot.y + _bslot.h);
}

/// The unit that was under the mouse last time it was checked (-1 = none)
function unit_LastHovered(_side) {
    if (!variable_global_exists("unit_hovered")) global.unit_hovered = { player: -1, enemy: -1 };
    return global.unit_hovered[$ _side];
}

/// Top-most living unit under a point, -1 when none
function unit_GetSlotAt(_side, _mx, _my) {
    var _order = unit_GetDepthOrder(_side, unit_LastHovered(_side));
    for (var i = array_length(_order) - 1; i >= 0; i--) {
        var _slot = _order[i];
        if (unit_IsAlive(_side, _slot) && unit_SpotContains(_side, _slot, _mx, _my)) return _slot;
    }
    return -1;
}

/// The unit under the mouse right now (remembered, so it stays on top while the mouse is on it)
function unit_GetHoveredSlot(_side) {
    var _slot = unit_GetSlotAt(_side, mouse_x, mouse_y);
    unit_LastHovered(_side);   // makes sure the memory exists
    global.unit_hovered[$ _side] = _slot;
    return _slot;
}

// ---------------------------------------------------------------------------
// Rows and frontline
//
// Each side stands in rows counted from the front (scr_battle_layout: battle_LayoutRow). While a
// living unit with the "frontline" keyword stands in a row, every unit in the rows BEHIND it takes
// no damage (attacks, attack_all and "damage" effects). Destroy / silence / shroud are not blocked.
// ---------------------------------------------------------------------------

/// Row of a spot, 0 = front (facing the other side)
function unit_GetRow(_side, _slot) {
    return battle_LayoutRow(_side, _slot);
}

function unit_IsBackRow(_side, _slot) {
    return _slot != UNIT_HERO && unit_GetRow(_side, _slot) > 0;
}

/// The front-most row with a living frontline unit in it, or -1 when there is none
function unit_GetFrontlineRow(_side) {
    var _row = -1;
    var _slots = unit_GetAliveSlots(_side);
    for (var i = 0; i < array_length(_slots); i++) {
        if (!card_HasKeyword(unit_Get(_side, _slots[i]), "frontline")) continue;
        var _r = unit_GetRow(_side, _slots[i]);
        if (_row < 0 || _r < _row) _row = _r;
    }
    return _row;
}

/// True when this unit can't take damage: a frontline unit stands in a row in front of it
function unit_IsGuarded(_side, _slot) {
    if (_slot == UNIT_HERO) return false;
    var _guard_row = unit_GetFrontlineRow(_side);
    return _guard_row >= 0 && unit_GetRow(_side, _slot) > _guard_row;
}

/// Living units on a side that can take damage right now (units behind a frontline left out)
function unit_GetDamageableSlots(_side) {
    var _slots = [];
    var _alive = unit_GetAliveSlots(_side);
    var _guard_row = unit_GetFrontlineRow(_side);
    for (var i = 0; i < array_length(_alive); i++) {
        if (_guard_row >= 0 && unit_GetRow(_side, _alive[i]) > _guard_row) continue;
        array_push(_slots, _alive[i]);
    }
    return _slots;
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

/// Defender for a single attack. Player side: the chosen monster if it is still there and not
/// guarded by a frontline, otherwise a random monster that can be hit, or the player when the board is empty.
function targets_AttackDefender(_side, _preferred_slot) {
    if (_side != SIDE_PLAYER) return targets_Single(_side, _preferred_slot);

    if (unit_Count(SIDE_PLAYER) <= 0) return targets_Single(SIDE_PLAYER, UNIT_HERO);

    var _target = _preferred_slot;
    if (_target < 0 || !unit_IsAlive(SIDE_PLAYER, _target) || unit_IsGuarded(SIDE_PLAYER, _target)) {
        var _open = unit_GetDamageableSlots(SIDE_PLAYER);
        _target = _open[irandom(array_length(_open) - 1)];   // never empty: the front-most guard is itself hittable
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
