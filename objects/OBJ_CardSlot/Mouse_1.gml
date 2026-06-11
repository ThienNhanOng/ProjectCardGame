/// @desc Remove card from deck when right-clicked

// Check if mouse is over this card
if (mouse_x > x && mouse_x < x + card_w &&
    mouse_y > y && mouse_y < y + card_h) {
    
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    
    // Find and remove this card from the deck
    for (var i = 0; i < array_length(_builder.selected_deck); i++) {
        if (_builder.selected_deck[i].id == card_id) {
            array_delete(_builder.selected_deck, i, 1);
            
            // RETURN THE CARD TO COLLECTION
            for (var c = 0; c < array_length(global.player_collection); c++) {
                if (global.player_collection[c].id == card_id) {
                    global.player_collection[c].owned++;
                    show_debug_message("Returned " + card_data.name + " to collection - Now owned: " + string(global.player_collection[c].owned));
                    break;
                }
            }
            
            // Refresh the collection view to update the card count
            _builder.SCR_DBC_LoadPage();
            
            // Visual feedback
            image_blend = c_white;
            
            show_debug_message("Removed from deck: " + card_data.name);
            break;
        }
    }
}