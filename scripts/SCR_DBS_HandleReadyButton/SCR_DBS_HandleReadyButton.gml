/// @desc Handle READY button click to start the game
/// Checks if player has at least 8 cards, then builds deck and transitions to game room

// Check if READY button was clicked
if (mouse_x > room_width - 150 && mouse_x < room_width - 20 &&
    mouse_y > room_height - 100 && mouse_y < room_height - 60) {
    
    // Verify deck has minimum 8 cards
    if (array_length(selected_deck) >= 8) {
        
        // Find the deck object in the game room
        var _deck_obj = instance_find(OBJ_Deck, 0);
        
        // Check if deck object exists
        if (_deck_obj == noone) {
            show_debug_message("ERROR: OBJ_Deck not found in room!");
            return;
        }
        
        // Clear the deck first (remove any previous cards)
        _deck_obj.deck_Clear();
        
        // Add all selected cards to the deck (pass only the ID, not the whole object)
        for (var i = 0; i < array_length(selected_deck); i++) {
            _deck_obj.deck_AddCard(selected_deck[i].id);
        }
        
        // Randomize card order
        _deck_obj.deck_Shuffle();
        
        show_debug_message("Deck built with " + string(array_length(selected_deck)) + " cards. Starting game...");
        
        // Transition to game room
        room_goto(rm_Game);
        
    } else {
        // Not enough cards selected
        show_debug_message("Need at least 8 cards to start! Current: " + string(array_length(selected_deck)));
    }
}