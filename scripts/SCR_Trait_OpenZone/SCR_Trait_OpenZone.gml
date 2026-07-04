/// @desc openzone — unlock hidden monster columns while this card stays on board

function battle_GetHiddenZoneSlotIndices() {
    return [3, 4];
}

function battle_InitZoneOwners() {
    board_zone_owner = [-1, -1];
}

function battle_OpenZonesFromMonster(_player_slot, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    var _hidden = battle_GetHiddenZoneSlotIndices();
    var _opened = 0;
    var _want = max(1, floor(_amount));

    for (var h = 0; h < array_length(_hidden) && _opened < _want; h++) {
        if (board_zone_owner[h] >= 0) continue;

        var _zone_slot = _hidden[h];
        with (_board) {
            if (_zone_slot < 0 || _zone_slot >= array_length(player_monster_slots)) continue;
            var _mslot = player_monster_slots[_zone_slot];
            if (_mslot.visible && !_mslot.locked) continue;
            SCR_Board_UnlockSlot(_zone_slot);
        }

        board_zone_owner[h] = _player_slot;
        _opened++;
}

    return _opened;
}

function battle_CloseZonesOwnedByMonster(_player_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    var _hidden = battle_GetHiddenZoneSlotIndices();
    for (var h = 0; h < array_length(_hidden); h++) {
        if (board_zone_owner[h] != _player_slot) continue;

        var _zone_slot = _hidden[h];
        with (_board) {
            SCR_Board_CloseHiddenSlot(_zone_slot);
        }
        board_zone_owner[h] = -1;
}
}

function trait_ExecuteOpenZone(_trait, _player_slot) {
    if (_player_slot < 0) return false;
    return battle_OpenZonesFromMonster(_player_slot, _trait.amount) > 0;
}
