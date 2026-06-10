/// @desc Add card to deck when clicked

// Get the deckbuilder object
var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);

// Debug: Check if deckbuilder exists
if (_deckbuilder == noone) {
    show_debug_message("ERROR: Cannot find OBJ_DeckBuilder!");
    exit;
}

// Debug: Show current deck size
show_debug_message("Card clicked: " + card_data.name);
show_debug_message("Current deck size: " + string(array_length(_deckbuilder.selected_deck)));

// Check if deck is not full (max 40 cards)
if (array_length(_deckbuilder.selected_deck) < 40) {
    // Add this card to the selected deck
    array_push(_deckbuilder.selected_deck, card_data);
    
    // Debug: Confirm addition
    show_debug_message("Added " + card_data.name + " to deck. New size: " + string(array_length(_deckbuilder.selected_deck)));
    
    // Visual feedback
    image_blend = c_lime;
    alarm[0] = 5;
} else {
    // Deck is full - show warning
    show_debug_message("Deck is full! Max 40 cards.");
    show_debug_message("Current deck size: " + string(array_length(_deckbuilder.selected_deck)));
    
    // Flash red
    image_blend = c_red;
    alarm[0] = 5;
}