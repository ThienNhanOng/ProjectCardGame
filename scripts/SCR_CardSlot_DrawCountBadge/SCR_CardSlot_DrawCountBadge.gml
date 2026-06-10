function SCR_CardSlot_DrawCountBadge() {
    if (count > 0) {
        draw_set_color(c_lime);
        draw_circle(x + card_w - 12, y + 12, 10, false);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(x + card_w - 12, y + 12, string(count));
    }
}