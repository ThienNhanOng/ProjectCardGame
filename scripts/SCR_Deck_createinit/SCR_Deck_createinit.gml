// ===== DECK INITIALIZATION SCRIPT =====
// Call this in OBJ_Deck Create Event: SCR_Deck_Init();

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
        if (_card.type != "spirit" && _card.type != "special_monster") continue;

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
        && (_data.type == "spirit" || _data.type == "special_monster")) {
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
    if (_data.type != "spirit" && _data.type != "special_monster") {
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

function deck_DrawCard() {
    if (deck_Count <= 0) {
return -1;
    }
    var _card_id = deck[deck_Head];
    deck_Head++;
    deck_Count--;
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

function deck_GetCardData(card_id) {
    for (var i = 0; i < array_length(card_DB.cards); i++) {
        if (card_DB.cards[i].id == card_id) {
            return card_DB.cards[i];
        }
    }
return undefined;
}

/// @desc Store immutable base HP from JSON so runtime damage cannot corrupt the DB template
function card_NormalizeDefinition(_raw) {
    if (_raw == undefined) return undefined;

    var _card = {};
    var _keys = variable_struct_get_names(_raw);
    for (var i = 0; i < array_length(_keys); i++) {
        var _key = _keys[i];
        if (_key == "max_health") continue;
        _card[$ _key] = _raw[$ _key];
    }

    var _base_hp = variable_struct_exists(_raw, "health") ? _raw.health : 10;
    _card.base_health = _base_hp;

    if (_card.type == "weapon") {
        weapon_EnsureAttackData(_card);
    }

    card_NormalizeCostsOnCard(_card);

    if ((!variable_struct_exists(_card, "tag") || !is_array(_card.tag) || array_length(_card.tag) <= 0)
        && variable_struct_exists(_raw, "tags") && is_array(_raw.tags)) {
        _card.tag = _raw.tags;
    }

    return _card;
}

function card_GetDefinitionHealth(_template) {
    if (_template == undefined) return 10;
    if (variable_struct_exists(_template, "base_health")) return _template.base_health;
    if (variable_struct_exists(_template, "health")) return _template.health;
    return 10;
}

/// @desc Deck-builder rarity: 0 = common, 1 = cultivated (extend switch for more tiers)
function card_GetRarity(_card) {
    if (_card == undefined) return 0;
    if (!variable_struct_exists(_card, "cardRarity")) return 0;
    return max(0, floor(real(_card.cardRarity)));
}

function card_GetTierLabel(_card) {
    if (_card == undefined) return "";
    if (_card.type == "spirit" || _card.type == "special_monster") return "";

    switch (card_GetRarity(_card)) {
        case 1: return "cultivated";
        default: return "common";
    }
}

function card_GetTierLabelColor(_card) {
    if (_card == undefined) return c_white;
    if (_card.type == "spirit" || _card.type == "special_monster") return c_purple;

    switch (card_GetRarity(_card)) {
        case 1: return c_yellow;
        default: return c_ltgray;
    }
}

/// @desc Shallow-copy a DB card so runtime stats (HP, etc.) are per-instance
function card_CreateRuntimeInstance(_template) {
    if (_template == undefined) return undefined;

    var _card = {};
    var _keys = variable_struct_get_names(_template);
    for (var i = 0; i < array_length(_keys); i++) {
        var _key = _keys[i];
        if (_key == "health" || _key == "max_health" || _key == "own") continue;
        _card[$ _key] = _template[$ _key];
    }

    var _base_hp = card_GetDefinitionHealth(_template);
    _card.base_health = _base_hp;
    _card.health = _base_hp;
    _card.max_health = _base_hp;
    _card.status_effects = [];
    _card.silenced_turns = 0;
    _card.shrouded_turns = 0;
    _card.silenced_ability_backup = undefined;
    _card.attack_buff = 0;

    if (_card.type == "weapon") {
        weapon_EnsureAttackData(_card);
    }

    card_NormalizeCostsOnCard(_card);

    return _card;
}

function deck_CreateRuntimeCard(_card_id) {
    var _card = card_CreateRuntimeInstance(deck_GetCardData(_card_id));
    if (_card != undefined) {
        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) trait_ChainApplyDeckIdCosts(_card, _card_id);
        }
    }
    return _card;
}

function deck_GetCardName(card_id) {
    var _card = deck_GetCardData(card_id);
    if (_card != undefined) {
        return _card.name;
    }
    return "Unknown";
}

function deck_IsValid() {
    return (deck_Count >= deck_Min && deck_Count <= deck_Max);
}

// Debug: Print all cards in deck
function deck_DebugPrint() {
for (var i = 0; i < deck_Count; i++) {
        var _card_id = deck[i];
        var _card_name = deck_GetCardName(_card_id);
}
}