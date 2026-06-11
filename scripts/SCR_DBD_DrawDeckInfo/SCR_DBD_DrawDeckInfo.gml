function SCR_DBD_DrawDeckInfo() {
    var _deck_size = array_length(selected_deck);
    
    // Deck count
    draw_set_color(c_white);
    draw_text(20, room_height - 85, "Deck: " + string(_deck_size) + "/40");
    
    // Ready button
    if (_deck_size >= 8) {
        draw_set_color(c_green);
    } else {
        draw_set_color(c_red);
    }
    draw_rectangle(room_width - 150, room_height - 100, room_width - 20, room_height - 60, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(room_width - 85, room_height - 88, "READY");
    draw_set_halign(fa_left);
}