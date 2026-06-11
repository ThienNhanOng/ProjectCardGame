/// @desc Handle READY button click to start the game

// Check if READY button was clicked
if (mouse_x > room_width - 150 && mouse_x < room_width - 20 &&
    mouse_y > room_height - 100 && mouse_y < room_height - 60) {
    
    // Verify deck has minimum 8 cards
    if (array_length(selected_deck) >= 8) {
        
        // Save the deck to a global variable for the battle room
        global.battle_deck = [];
        for (var i = 0; i < array_length(selected_deck); i++) {
            array_push(global.battle_deck, selected_deck[i].id);
        }
        
        show_debug_message("Deck saved to global.battle_deck. Cards: " + string(array_length(global.battle_deck)));
        
        // Transition to battle room
        room_goto(Room_battle);  // ← Use your actual room name
        
    } else {
        show_debug_message("Need at least 8 cards to start! Current: " + string(array_length(selected_deck)));
    }
}