/// @desc Handle READY button click to start the game
/// Checks if player has at least 8 cards, then builds deck and transitions to game room

// Check if READY button was clicked
if (mouse_x > room_width - 150 && mouse_x < room_width - 20 &&
    mouse_y > room_height - 100 && mouse_y < room_height - 60) {
    
    // Verify deck has minimum 8 cards
    if (array_length(selected_deck) >= 8) {
        // Find the deck object in the game room
        var _deck_obj = instance_find(OBJ_Deck, 0);
        
        // Add all selected cards to the deck
        for (var i = 0; i < array_length(selected_deck); i++) {
            _deck_obj.deck_AddCard(selected_deck[i]);
        }
        
        // Randomize card order
        _deck_obj.deck_Shuffle();
        
        // Transition to game room
        room_goto(rm_Game);
    } else {
        // Not enough cards selected
}
}