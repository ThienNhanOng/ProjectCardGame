/// @desc Show card info on right-click

if (mouse_x > x && mouse_x < x + card_w &&
    mouse_y > y && mouse_y < y + card_h) {
    
    show_debug_message("Card Info: " + card_data.name + " (Level " + string(card_data.level) + ")");
}