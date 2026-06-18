function SCR_DBS_HandleDeckClick() {
    if (!mouse_check_button_pressed(mb_left)) return;
    
    for (var i = 0; i < array_length(selected_deck); i++) {
        var _y = 80 + (i * 18);
        
        if (mouse_x > room_width - 300 && mouse_x < room_width - 20 &&
            mouse_y > _y - 9 && mouse_y < _y + 9) {
            
            var _removed = selected_deck[i];
            
            // Remove from deck
            array_delete(selected_deck, i, 1);
            
            // DO NOT touch owned — available is always derived as owned - in_deck
            show_debug_message("Returned " + _removed.name + " to collection");
            
            // Refresh recalculates counts automatically
            SCR_DBC_LoadPage();
            
            break;
        }
    }
}