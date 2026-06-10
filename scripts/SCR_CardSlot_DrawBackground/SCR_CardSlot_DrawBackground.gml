function SCR_CardSlot_DrawBackground() {
    draw_set_color(c_white);
    draw_rectangle(x, y, x + card_w, y + card_h, false);
    draw_set_color(c_black);
    draw_rectangle(x, y, x + card_w, y + card_h, true);
}