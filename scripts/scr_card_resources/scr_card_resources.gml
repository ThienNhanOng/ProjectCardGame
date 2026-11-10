/// @desc Resource and board-position effects of traits, plus the add_cost trait chain.
/// Used by player cards (these effects need the source card's board slot or the player's resources).

// ---------------------------------------------------------------------------
// Effects on the source's own board position (player monsters / weapons)
// ---------------------------------------------------------------------------

/// openzone — open closed back-row spots while the source stays on board (needs a board slot:
/// a monster, or a weapon on one; an action card has nothing to keep the spot open)
function card_OpenZones(_source, _amount) {
    if (_source.side != SIDE_PLAYER || _source.slot < 0) return false;
    return battle_OpenBackRowSpots(_source.slot, _amount) > 0;
}

/// add_counter — extra resources this turn (tracked per source slot)
function card_AddResourceCounter(_source, _amount) {
    return battle_AddResourcesTemporary(max(1, _amount), _source.slot);
}

/// remove_counter — lower max resources while the source stays on board
function card_RemoveResourceCounter(_source, _amount) {
    return battle_RemoveResourcesMaxFromSlot(max(1, _amount), _source.slot);
}

/// no_board_expire — the source monster never expires from the board
function card_SetNoBoardExpire(_source) {
    var _card = unit_Get(SIDE_PLAYER, _source.slot);
    if (_card == undefined) return false;
    battle_SetBoardMonsterExpire(_card, false);
    return true;
}

/// add_board_turns — the source monster stays on board longer
function card_AddBoardTurns(_source, _amount) {
    var _card = unit_Get(SIDE_PLAYER, _source.slot);
    if (_card == undefined) return false;
    return battle_AddBoardMonsterTurns(_card, max(1, _amount));
}

// ---------------------------------------------------------------------------
// Back row opened by openzone
// Your back row (spots 3 and 4) starts closed. openzone opens up to "amount" of them (1 or 2); each
// spot remembers the column that opened it (slot.opened_by) and closes again when that monster leaves.
// ---------------------------------------------------------------------------

/// Open up to _amount closed back-row spots for the monster in column _owner_slot. Returns how many opened.
function battle_OpenBackRowSpots(_owner_slot, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    var _want = max(1, floor(_amount));
    var _opened = 0;
    with (_board) {
        for (var i = PLAYER_FRONT_ROW_SLOTS; i < array_length(player_monster_slots) && _opened < _want; i++) {
            if (SCR_Board_OpenBackSlot(i, _owner_slot)) _opened++;
        }
    }
    return _opened;
}

/// The monster in column _owner_slot is leaving: close the back-row spots it opened.
/// Whoever stands in such a spot leaves the board too (combat_RemoveUnit, so its own effects end).
function battle_CloseBackRowSpotsOf(_owner_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = PLAYER_FRONT_ROW_SLOTS; i < array_length(_board.player_monster_slots); i++) {
        if (_board.player_monster_slots[i].opened_by != _owner_slot) continue;
        combat_RemoveUnit(SIDE_PLAYER, i);
        with (_board) SCR_Board_CloseBackSlot(i);
    }
}

// ---------------------------------------------------------------------------
// Trait chain — cards added during one play, so a later add_cost trait can tax them
// (runs on OBJ_BattleManager)
// ---------------------------------------------------------------------------

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

/// add_cost with no picked card — taxes every card added earlier/later in the same chain
function trait_ExecuteAddCostToChain(_trait) {
    var _entry = card_BuildCostEntryFromTrait(_trait);
    if (_entry == undefined) return false;

    array_push(trait_pending_add_cost_entries, _entry);

    for (var i = 0; i < array_length(trait_chain_added_cards); i++) {
        card_AppendCostEntry(trait_chain_added_cards[i], _entry);
    }
    for (var d = 0; d < array_length(trait_chain_added_deck_ids); d++) {
        trait_ApplyDeckIdCostEntry(trait_chain_added_deck_ids[d], _entry);
    }
    return true;
}
