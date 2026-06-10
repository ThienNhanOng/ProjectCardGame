function SCR_CardSlot_CheckClick() {
    if (mouse_check_button_pressed(mb_left)) {
        if (mouse_x > x && mouse_x < x + card_w && 
            mouse_y > y && mouse_y < y + card_h) {
            return true;
        }
    }
    return false;
}