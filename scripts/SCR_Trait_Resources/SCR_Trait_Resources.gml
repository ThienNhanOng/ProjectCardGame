/// @desc Resource traits — add_counter, remove_counter, add_cost

function trait_ChainReset() {
    trait_chain_added_cards = [];
    trait_chain_added_deck_ids = [];
    trait_pending_add_cost_entries = [];
}

function trait_ChainFinish() {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck != noone && _deck.tag_picker_open) return;

    trait_chain_added_cards = [];
    trait_chain_added_deck_ids = [];
    trait_pending_add_cost_entries = [];
}

function trait_ApplyDeckIdCostEntry(_card_id, _entry) {
    if (_card_id <= 0 || _entry == undefined) return;

    var _key = string(_card_id);
    if (!variable_struct_exists(trait_chain_deck_id_costs, _key)) {
        trait_chain_deck_id_costs[$ _key] = [];
    }
    array_push(trait_chain_deck_id_costs[$ _key], _entry);
}

function trait_ChainApplyDeckIdCosts(_card, _card_id) {
    if (_card == undefined || _card_id <= 0) return;

    var _key = string(_card_id);
    if (!variable_struct_exists(trait_chain_deck_id_costs, _key)) return;

    var _entries = trait_chain_deck_id_costs[$ _key];
    for (var i = 0; i < array_length(_entries); i++) {
        card_AppendCostEntry(_card, _entries[i]);
    }
}

function trait_ChainRegisterAddedCard(_card) {
    if (_card == undefined) return;

    array_push(trait_chain_added_cards, _card);
    for (var i = 0; i < array_length(trait_pending_add_cost_entries); i++) {
        card_AppendCostEntry(_card, trait_pending_add_cost_entries[i]);
    }
}

function trait_ChainRegisterAddedDeckId(_card_id) {
    if (_card_id <= 0) return;

    array_push(trait_chain_added_deck_ids, _card_id);
    for (var i = 0; i < array_length(trait_pending_add_cost_entries); i++) {
        trait_ApplyDeckIdCostEntry(_card_id, trait_pending_add_cost_entries[i]);
    }
}

function trait_ExecuteAddCostToChain(_trait) {
    var _entry = card_BuildCostEntryFromTrait(_trait);
    if (_entry == undefined) return false;

    array_push(trait_pending_add_cost_entries, _entry);

    var _applied = false;
    for (var i = 0; i < array_length(trait_chain_added_cards); i++) {
        if (card_AppendCostEntry(trait_chain_added_cards[i], _entry)) _applied = true;
    }
    for (var d = 0; d < array_length(trait_chain_added_deck_ids); d++) {
        trait_ApplyDeckIdCostEntry(trait_chain_added_deck_ids[d], _entry);
        _applied = true;
    }

    show_debug_message((_applied ? "Add cost applied: " : "Add cost queued: ") + card_FormatCostEntry(_entry));
    return true;
}

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
