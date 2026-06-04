// check if ready button was clicked
if (mouse_x > room_width - 150 && mouse_x < room_width - 20
&&  mouse_y > room_height - 60 && mouse_y < room_height - 20) {
    if (array_length(selected_deck) >= 8) {
        var _deck_obj = instance_find(OBJ_Deck, 0);
        for (var i = 0; i < array_length(selected_deck); i++) {
            _deck_obj.deck_AddCard(selected_deck[i]);
        }
        _deck_obj.deck_Shuffle();
        room_goto(rm_Game);
    } else {
        show_debug_message("Need at least 8 cards!");
    }
}