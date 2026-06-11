function SCR_DBS_HandleDeckClick() {
    if (!mouse_check_button_pressed(mb_left)) return;
    
    for (var i = 0; i < array_length(selected_deck); i++) {
        var _y = 80 + (i * 18);
        
        if (mouse_x > room_width - 180 && mouse_x < room_width - 20 &&
            mouse_y > _y - 9 && mouse_y < _y + 9) {
            
            var _removed = selected_deck[i];
            
            // Remove from deck
            array_delete(selected_deck, i, 1);
            
            // Return to collection (increase owned count)
            for (var c = 0; c < array_length(global.player_collection); c++) {
                if (global.player_collection[c].id == _removed.id) {
                    global.player_collection[c].owned++;
                    show_debug_message("Returned " + _removed.name + " - Now owned: " + string(global.player_collection[c].owned));
                    break;
                }
            }
            
            // Refresh the collection - this recreates the card
            SCR_DBC_LoadPage();
            
            break;
        }
    }
}