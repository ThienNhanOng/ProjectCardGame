function SCR_CardSlot_DrawLevel() {
    if (variable_struct_exists(card_data, "level")) {
        draw_set_color(c_green);
        draw_set_halign(fa_left);
        draw_set_valign(fa_bottom);
        draw_text(x + 26, y + card_h - 0, "Lv " + string(card_data.level));
    }
}