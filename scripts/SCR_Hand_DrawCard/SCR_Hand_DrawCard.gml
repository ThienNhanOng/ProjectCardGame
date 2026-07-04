function SCR_Hand_DrawCard(_index, _count, _spacing, _hovered, _start_x) {
    var _card = hand[_index];
    if (_card == undefined) return;

    var _box = SCR_Hand_GetCardHitbox(_index, _count, _spacing, hand_Y, _start_x, _hovered);
    var _w = _box.right - _box.left;
    var _h = _box.bottom - _box.top;
    card_DrawFramedInRect(_box.left, _box.top, _w, _h, _card, 1);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_black);
    draw_text(_box.left + 6, _box.top + 8, SCR_Hand_GetCardNameLabel(_card.name, _box, _hovered));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
