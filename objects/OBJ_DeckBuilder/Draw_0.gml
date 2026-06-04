show_debug_message("OBJ_DeckBuilder Create fired!"); 
// draw deck count
draw_set_color(c_white);
draw_text(20, room_height - 60, "Deck: " + string(array_length(selected_deck)) + "/" + string(40));

// ready button color based on validity
if (array_length(selected_deck) >= 8) {
    draw_set_color(c_green);
} else {
    draw_set_color(c_red);
}
draw_rectangle(room_width - 150, room_height - 60, room_width - 20, room_height - 20, false);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_text(room_width - 85, room_height - 48, "READY");
draw_set_halign(fa_left);