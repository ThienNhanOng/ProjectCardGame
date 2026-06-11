function SCR_DBD_DrawDeckList() {
    var _deck_size = array_length(selected_deck);
    var _list_x = room_width - 180;
    
    // Header
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_list_x, 60, "=== YOUR DECK ===");
    
    // Card list
    for (var i = 0; i < _deck_size; i++) {
        var _y = 80 + (i * 18);
        
        if (_y > room_height - 100) {
            draw_text(_list_x, _y, "... and more");
            break;
        }
        
        draw_text(_list_x, _y, string(i + 1) + ". " + selected_deck[i].name);
    }
    
    // Total counter
    draw_set_color(c_yellow);
    draw_text(_list_x, room_height - 50, "Total: " + string(_deck_size) + " / 40 cards");
    
    // Warning
    if (_deck_size < 8) {
        draw_set_color(c_red);
        draw_text(_list_x, room_height - 30, "Need at least 8 cards to start!");
    }
}