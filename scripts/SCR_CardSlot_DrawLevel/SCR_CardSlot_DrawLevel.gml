function SCR_CardSlot_DrawLevel() {
    var _label = card_GetTierLabel(card_data);
    if (_label == "") return;

    draw_set_color(card_GetTierLabelColor(card_data));
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);
    draw_text(x + 8, y + card_h, _label);
}
