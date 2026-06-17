function SCR_DBD_DrawDeckInfo() {
    var _deck_size = array_length(selected_deck);
    
    // Deck count - aligned under the collection container
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_text(container_x, container_y + container_h + 10, "Deck: " + string(_deck_size) + "/40");
    
    // Divider
    draw_text(container_x + 90, container_y + container_h + 10, "|");
    
    // Spirit count - to the right of the divider
    var _spirit_owned = 0;
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (_card.type == "spirit") {
            _spirit_owned += _card.owned;
        }
    }
    draw_text(container_x + 105, container_y + container_h + 10, "Spirit: " + string(_spirit_owned));
    
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