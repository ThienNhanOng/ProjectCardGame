function SCR_CardSlot_HandleClick() {
    // Check if left mouse button is pressed over this card
    if (mouse_check_button_pressed(mb_left)) {
        if (mouse_x > x && mouse_x < x + card_w && 
            mouse_y > y && mouse_y < y + card_h) {
            
            var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
            if (_deckbuilder != noone) {
                if (array_length(_deckbuilder.selected_deck) < 40) {
                    array_push(_deckbuilder.selected_deck, card_data);
                    image_blend = c_lime;
                    alarm[0] = 5;
                    show_debug_message("Added " + card_data.name);
                } else {
                    image_blend = c_red;
                    alarm[0] = 5;
                    show_debug_message("Deck full!");
                }
            }
        }
    }
}