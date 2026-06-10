/// @desc Remove card from deck when right-clicked

var _deckbuilder = OBJ_DeckBuilder;

// Find and remove this card from the deck
for (var i = 0; i < array_length(_deckbuilder.selected_deck); i++) {
    if (_deckbuilder.selected_deck[i].id == card_data.id) {
        array_delete(_deckbuilder.selected_deck, i, 1);
        break;  // Remove only one copy
    }
}

// Visual feedback
image_blend = c_white;
alarm[0] = 5;