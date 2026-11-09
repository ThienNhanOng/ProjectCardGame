/// @desc OBJ_Deck — main deck and extra deck contents

function SCR_Deck_createinit() {
	
    // ===== DECK PROPERTIES =====
    deck_X = 548;
    deck_Y = 478;
    deck_Width = 73;
    deck_Height = 101;
    deck_Min = 8;
    deck_Max = collection_GetDeckMaxSize();
    deck_Count = 0;
    deck_Head = 0;

    extra_deck_Max = 9999;
    extra_deck_Count = 0;
    extra_deck = [];

	deck = []; 
	
    // Card slots (stores card IDs)
    for (var i = 0; i < deck_Max; i++) {
        deck[i] = 0;
    }

    for (var e = 0; e < extra_deck_Max; e++) {
        extra_deck[e] = 0;
    }

    extra_deck_X = 548;
    extra_deck_Y = 371.5;
    extra_deck_Width = 73;
    extra_deck_Height = 101;
    extra_deck_picker_open = false;
    extra_deck_picker_scroll = 0;
    extra_deck_picker_focus = 0;

    tag_picker_open = false;
    tag_picker_scroll = 0;
    tag_picker_focus = 0;
    tag_picker_card_ids = [];
    tag_picker_destination = "";
    tag_picker_amount = 1;
    tag_picker_title = "";
    tag_picker_footer_hint = "";
    tag_picker_apply_cost = 0;
    
    deck_LoadFromBattleSource();
    deck_SnapshotInitialMainDeck();
}

function deck_LoadFromBattleSource() {
    deck_Clear();

    extra_deck_Count = 0;
    for (var e = 0; e < extra_deck_Max; e++) {
        extra_deck[e] = 0;
    }

    var _source = battle_GetDeckSourceCopy();
    if (array_length(_source) > 0) {
        for (var i = 0; i < array_length(_source); i++) {
            if (deck_Count >= deck_Max) break;
            deck[deck_Count] = _source[i];
            deck_Count++;
        }
        deck_Shuffle();
    } else {
        deck_AddCard(1);
        deck_AddCard(2);
        deck_AddCard(3);
        deck_Shuffle();
    }

    var _extra_source = battle_GetExtraDeckSourceCopy();
    if (array_length(_extra_source) > 0) {
        for (var j = 0; j < array_length(_extra_source); j++) {
            deck_AddExtraCardEntry(_extra_source[j]);
        }
    } else {
        deck_LoadExtraDeckFromCollection();
    }
}

function deck_LoadExtraDeckFromCollection() {
    var _extra_source = battle_GetExtraDeckSourceCopy();
    if (array_length(_extra_source) > 0) {
        for (var i = 0; i < array_length(_extra_source); i++) {
            deck_AddExtraCardEntry(_extra_source[i]);
        }
        return;
    }

    if (!variable_global_exists("player_collection") || !is_array(global.player_collection)) {
        return;
    }

    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (!card_IsSpiritType(_card)) continue;

        var _owned = variable_struct_exists(_card, "owned") ? _card.owned : 0;
        if (_owned <= 0) continue;

        for (var c = 0; c < _owned; c++) {
            if (!deck_AddExtraCard(_card.id)) break;
        }
    }

}

// ===== DECK FUNCTIONS =====
function deck_AddCard(card_id) {
    if (deck_Count >= deck_Max) {
        return false;
    }

    var _data = deck_GetCardData(card_id);
    if (_data != undefined
        && card_IsSpiritType(_data)) {
        return false;
    }

    deck[deck_Count] = card_id;
    deck_Count++;
    deck_Shuffle(true);
    return true;
}

function deck_AddExtraCard(_card_id) {
    return deck_AddExtraCardEntry(_card_id);
}

function deck_AddExtraCardEntry(_entry_or_id) {
    var _entry = extraDeck_NormalizeEntry(_entry_or_id);
    if (_entry == undefined) return false;

    var _data = deck_GetCardData(extraDeck_GetCardId(_entry));
    if (_data == undefined) {
        return false;
    }
    if (!card_IsSpiritType(_data)) {
        return false;
    }

    extra_deck[extra_deck_Count] = _entry;
    extra_deck_Count++;
    return true;
}

function deck_SnapshotInitialMainDeck() {
    var _snap = [];
    for (var i = 0; i < deck_Count; i++) {
        array_push(_snap, deck[deck_Head + i]);
    }

    if (array_length(_snap) > 0) {
        global.battle_initial_main_deck = _snap;
    } else if (!variable_global_exists("battle_initial_main_deck")
        || !is_array(global.battle_initial_main_deck)
        || array_length(global.battle_initial_main_deck) <= 0) {
        global.battle_initial_main_deck = battle_GetDeckSourceCopy();
    }
}

/// @desc Restore draw pile from the main-deck clone saved at battle start
function deck_RebuildMainDeckFromInitial() {
    var _source = battle_GetInitialMainDeckCopy();
    if (array_length(_source) <= 0) return false;

    deck_Clear();
    for (var i = 0; i < array_length(_source); i++) {
        if (deck_Count >= deck_Max) break;
        deck[deck_Count] = _source[i];
        deck_Count++;
    }

    deck_Head = 0;
    deck_Shuffle(true);
    return deck_Count > 0;
}

/// Take the top card. Remaining cards always stay at deck[0 .. deck_Count-1] (deck_Head stays 0),
/// so adding, shuffling and searching the deck all see exactly the cards still in it.
function deck_DrawCard() {
    if (deck_Count <= 0) {
        return -1;
    }
    var _card_id = deck[0];
    for (var i = 1; i < deck_Count; i++) {
        deck[i - 1] = deck[i];
    }
    deck_Count--;
    deck[deck_Count] = 0;
    deck_Head = 0;
    return _card_id;
}

function deck_Shuffle(_quiet = false) {
    for (var i = deck_Count - 1; i > 0; i--) {
        var _j = irandom(i);
        var _temp = deck[i];
        deck[i] = deck[_j];
        deck[_j] = _temp;
    }
    deck_Head = 0;
    if (!_quiet) {
    }
}

function deck_Clear() {
    for (var i = 0; i < deck_Max; i++) {
        deck[i] = 0;
    }
    deck_Count = 0;
    deck_Head = 0;
}
