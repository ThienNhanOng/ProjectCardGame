// === COORDINATES ===
deck_X = 548;
deck_Y = 478;

// === DIMENSIONS ===
deck_Width  = 73;
deck_Height = 101;

// === LIMITS ===
deck_Min = 8;
deck_Max = 40;

// === STATE ===
deck_Count = 0;   // how many cards are in the deck
deck_Head  = 0;   // index of the top card (used when drawing)

// === CARD SLOTS ===
// stores card IDs only — full data is fetched from card_DB when needed
for (var i = 0; i < deck_Max; i++) {
    deck[i] = 0;
}

// -------------------------------------------------------
// FUNCTION: Add a card to the deck by ID
// -------------------------------------------------------
function deck_AddCard(card_id) {
    if (deck_Count >= deck_Max) {
        show_debug_message("Deck full! Cannot add card " + string(card_id));
        return false;
    }
    deck[deck_Count] = card_id;
    deck_Count++;
    return true;
}

// -------------------------------------------------------
// FUNCTION: Draw the top card (returns card ID)
// -------------------------------------------------------
function deck_DrawCard() {
    if (deck_Count <= 0) {
        show_debug_message("Deck is empty!");
        return -1;
    }
    var _card_id  = deck[deck_Head];
    deck_Head++;
    deck_Count--;
    return _card_id;
}

// -------------------------------------------------------
// FUNCTION: Shuffle the deck (Fisher-Yates)
// -------------------------------------------------------
function deck_Shuffle() {
    for (var i = deck_Count - 1; i > 0; i--) {
        var _j        = irandom(i);
        var _temp     = deck[i];
        deck[i]       = deck[_j];
        deck[_j]      = _temp;
    }
    deck_Head = 0;  // reset draw pointer after shuffle
    show_debug_message("Deck shuffled. Cards: " + string(deck_Count));
}

// -------------------------------------------------------
// FUNCTION: Look up full card data from the DB by ID
// -------------------------------------------------------
function deck_GetCardData(card_id) {
    var _cards = card_DB.cards;
    for (var i = 0; i < array_length(_cards); i++) {
        if (_cards[i].id == card_id) {
            return _cards[i];
        }
    }
    show_debug_message("Card ID not found: " + string(card_id));
    return undefined;
}

// -------------------------------------------------------
// FUNCTION: Validate deck meets min/max rules
// -------------------------------------------------------
function deck_IsValid() {
    return (deck_Count >= deck_Min && deck_Count <= deck_Max);
}

