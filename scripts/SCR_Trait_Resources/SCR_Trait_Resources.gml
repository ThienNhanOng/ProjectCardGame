/// @desc Resource traits — add_counter, remove_counter, add_cost

function trait_ExecuteAddCounter(_trait, _player_slot = -1) {
    return battle_AddResourcesTemporary(max(1, _trait.amount), _player_slot);
}

function trait_ExecuteRemoveCounter(_trait, _player_slot = -1) {
    return battle_RemoveResourcesMaxFromSlot(max(1, _trait.amount), _player_slot);
}

function trait_ExecuteAddCost(_trait, _target_card) {
    if (_target_card == undefined) return false;

    var _entry = card_BuildCostEntryFromTrait(_trait);
    if (_entry == undefined) return false;

    return card_AppendCostEntry(_target_card, _entry);
}

function battle_PickAddCostTargetAt(_mx, _my) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand != noone && _hand.hand_Count > 0) {
        var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
        var _hand_idx = SCR_Hand_PickCardIndex(_mx, _my, _hand.hand_Count, _spacing, _hand.hand_Y);
        if (_hand_idx >= 0) {
            return { card: _hand.hand[_hand_idx], source: "hand" };
        }
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return undefined;

    with (_board) {
        if (action_slot.visible && action_slot.occupied && action_slot.card != undefined
            && SCR_Board_IsSlotMouseOver(action_slot)) {
            return { card: action_slot.card, source: "board" };
        }

        for (var w = 0; w < array_length(player_weapon_slots); w++) {
            var _wslot = player_weapon_slots[w];
            if (!_wslot.visible || !_wslot.occupied || _wslot.card == undefined) continue;
            if (SCR_Board_IsSlotMouseOver(_wslot)) {
                return { card: _wslot.card, source: "board" };
            }
        }

        for (var m = 0; m < array_length(player_monster_slots); m++) {
            var _mslot = player_monster_slots[m];
            if (!_mslot.visible || !_mslot.occupied || _mslot.card == undefined) continue;
            if (SCR_Board_IsSlotMouseOver(_mslot)) {
                return { card: _mslot.card, source: "board" };
            }
        }
    }

    return undefined;
}

function battle_ExecuteMonsterOnPlayAddCostTrait(_player_slot, _trait_index, _target_card) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _slot = _board.player_monster_slots[_player_slot];
    if (!_slot.occupied || _slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "add_cost") return false;

    return trait_ExecuteAddCost(_traits[_trait_index], _target_card);
}

function battle_ExecuteWeaponOnPlayAddCostTrait(_weapon_column, _trait_index, _target_card) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _weapon_slot = _board.player_weapon_slots[_weapon_column];
    if (!_weapon_slot.occupied || _weapon_slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_weapon_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "add_cost") return false;

    return trait_ExecuteAddCost(_traits[_trait_index], _target_card);
}

function battle_ExecuteActionAddCost(_trait_index, _target_card) {
    var _traits = battle_GetActionTraits();
    if (_trait_index < 0 || _trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "add_cost") return false;

    return trait_ExecuteAddCost(_traits[_trait_index], _target_card);
}

function battle_HandleAddCostPick(_target_card) {
    if (_target_card == undefined) return;

    if (pending_trait_source == "monster_on_play") {
        if (battle_ExecuteMonsterOnPlayAddCostTrait(pending_monster_slot, pending_monster_trait_index, _target_card)) {
            battle_MonsterOnPlayContinue(pending_monster_slot, pending_monster_trait_index);
        }
        return;
    }

    if (pending_trait_source == "weapon_on_play") {
        if (battle_ExecuteWeaponOnPlayAddCostTrait(pending_weapon_slot, pending_monster_trait_index, _target_card)) {
            battle_WeaponOnPlayContinue(pending_weapon_slot, pending_monster_trait_index);
        }
        return;
    }

    if (battle_ExecuteActionAddCost(pending_action_trait_index, _target_card)) {
        battle_TargetingContinueAfterAction(pending_action_trait_index);
    }
}
