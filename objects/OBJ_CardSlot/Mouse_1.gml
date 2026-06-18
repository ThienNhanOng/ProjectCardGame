/// @desc Remove card from deck when right-clicked

// Check if mouse is over this card
if (mouse_x > x && mouse_x < x + card_w &&
    mouse_y > y && mouse_y < y + card_h) {
    
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    
    // Find and remove this card from the deck
    for (var i = 0; i < array_length(_builder.selected_deck); i++) {
        if (_builder.selected_deck[i].id == card_id) {
            array_delete(_builder.selected_deck, i, 1);
            show_debug_message("Returned " + card_data.name + " to collection");
            SCR_DBD_RebuildGrid();
            
            // Visual feedback
            image_blend = c_white;
            
            show_debug_message("Removed from deck: " + card_data.name);
            break;
        }
    }
}