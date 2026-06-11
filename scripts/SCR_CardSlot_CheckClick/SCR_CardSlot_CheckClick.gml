function SCR_CardSlot_CheckClick() {
    if (global.mouse_left_pressed) {
        if (mouse_x > x && mouse_x < x + card_w && 
            mouse_y > y && mouse_y < y + card_h) {
            global.mouse_left_pressed = false;
            return true;
        }
    }
    return false;
}