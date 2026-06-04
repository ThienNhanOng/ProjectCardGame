// check if the READY button was clicked
if (mouse_x > room_width - 150 && mouse_x < room_width - 20
&&  mouse_y > room_height - 60 && mouse_y < room_height - 20) {
    
    // only proceed if player has selected at least 8 cards
    if (array_length(selected_deck) >= 8) {
        
        // get reference to the deck object in room_battle
        var _deck_obj = instance_find(OBJ_Deck, 0);
        
        // add every selected card into the deck
        for (var i = 0; i < array_length(selected_deck); i++) {
            _deck_obj.deck_AddCard(selected_deck[i]);
        }
        
        // shuffle the deck before heading to battle
        _deck_obj.deck_Shuffle();
        
        // go to the battle room
        room_goto(Room_battle);
        
    } else {
        // not enough cards selected yet
        show_debug_message("Need at least 8 cards!");
    }
}