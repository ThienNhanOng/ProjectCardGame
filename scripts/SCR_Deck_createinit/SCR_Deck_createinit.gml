// ===== DECK INITIALIZATION SCRIPT =====
// Call this in OBJ_Deck Create Event: SCR_Deck_Init();

function SCR_Deck_createinit() {
	
    // ===== DECK PROPERTIES =====
    deck_X = 548;
    deck_Y = 478;
    deck_Width = 73;
    deck_Height = 101;
    deck_Min = 8;
    deck_Max = 40;
    deck_Count = 0;
    deck_Head = 0;
    
	deck = []; 
	
    // Card slots (stores card IDs)
    for (var i = 0; i < deck_Max; i++) {
        deck[i] = 0;
    }
    
    // Load deck from global variable (saved from deckbuilder)
    if (variable_global_exists("battle_deck") && array_length(global.battle_deck) > 0) {
        for (var i = 0; i < array_length(global.battle_deck); i++) {
            deck_AddCard(global.battle_deck[i]);
        }
        deck_Shuffle();
        show_debug_message("Loaded " + string(deck_Count) + " cards into battle deck");
        global.battle_deck = undefined;
    } else {
        show_debug_message("No battle deck found! Using default cards.");
        deck_AddCard(1);
        deck_AddCard(2);
        deck_AddCard(3);
        deck_Shuffle();
    }
}

// ===== DECK FUNCTIONS =====
function deck_AddCard(card_id) {
    if (deck_Count >= deck_Max) {
        show_debug_message("Deck full! Cannot add card " + string(card_id));
        return false;
    }
    deck[deck_Count] = card_id;
    deck_Count++;
    return true;
}

function deck_DrawCard() {
    if (deck_Count <= 0) {
        show_debug_message("Deck is empty!");
        return -1;
    }
    var _card_id = deck[deck_Head];
    deck_Head++;
    deck_Count--;
    return _card_id;
}

function deck_Shuffle() {
    for (var i = deck_Count - 1; i > 0; i--) {
        var _j = irandom(i);
        var _temp = deck[i];
        deck[i] = deck[_j];
        deck[_j] = _temp;
    }
    deck_Head = 0;
    show_debug_message("Deck shuffled. Cards: " + string(deck_Count));
}

function deck_GetCardData(card_id) {
    for (var i = 0; i < array_length(card_DB.cards); i++) {
        if (card_DB.cards[i].id == card_id) {
            return card_DB.cards[i];
        }
    }
    show_debug_message("Card ID not found: " + string(card_id));
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
    return _card;
}

function card_GetDefinitionHealth(_template) {
    if (_template == undefined) return 10;
    if (variable_struct_exists(_template, "base_health")) return _template.base_health;
    if (variable_struct_exists(_template, "health")) return _template.health;
    return 10;
}

/// @desc Shallow-copy a DB card so runtime stats (HP, etc.) are per-instance
function card_CreateRuntimeInstance(_template) {
    if (_template == undefined) return undefined;

    var _card = {};
    var _keys = variable_struct_get_names(_template);
    for (var i = 0; i < array_length(_keys); i++) {
        var _key = _keys[i];
        if (_key == "health" || _key == "max_health") continue;
        _card[$ _key] = _template[$ _key];
    }

    var _base_hp = card_GetDefinitionHealth(_template);
    _card.base_health = _base_hp;
    _card.health = _base_hp;
    _card.max_health = _base_hp;
    _card.status_effects = [];
    _card.silenced_turns = 0;
    return _card;
}

function deck_CreateRuntimeCard(_card_id) {
    return card_CreateRuntimeInstance(deck_GetCardData(_card_id));
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
    show_debug_message("=== DECK CONTENTS ===");
    for (var i = 0; i < deck_Count; i++) {
        var _card_id = deck[i];
        var _card_name = deck_GetCardName(_card_id);
        show_debug_message("Slot " + string(i) + ": ID " + string(_card_id) + " - " + _card_name);
    }
    show_debug_message("Total cards: " + string(deck_Count));
}