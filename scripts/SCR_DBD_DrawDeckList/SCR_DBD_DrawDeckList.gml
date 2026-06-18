function SCR_DBD_DrawDeckList() {
    var _layout = SCR_DBD_GetDeckListLayout();
    var _unique_cards = SCR_DBD_GetDeckListSummary(selected_deck);

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_layout.list_x, 60, "=== YOUR DECK ===");

    var _total_cards = 0;
    var _unique_count = array_length(_unique_cards);
    for (var i = 0; i < _unique_count; i++) {
        var _bounds = SCR_DBD_GetDeckListRowBounds(_layout, i);

        if (_bounds.y > room_height - 100) {
            draw_set_color(c_ltgray);
            draw_text(_layout.list_x, _bounds.y, "... and more");
            break;
        }

        var _card = _unique_cards[i];
        _total_cards += _card.count;

        var _line = string(i + 1) + ". " + _card.name + " x" + string(_card.count);
        var _is_hovered = SCR_DBD_IsDeckListRowHovered(_bounds);
        SCR_DBD_DrawDeckListRow(_layout, _bounds, SCR_Hand_TruncateName(_line, _layout.list_w - _layout.text_pad_x * 2), _is_hovered);
    }

    draw_set_color(c_yellow);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_layout.list_x, room_height - 50, "Total: " + string(_total_cards) + " / 40 cards");

    if (_total_cards < 8) {
        draw_set_color(c_red);
        draw_text(_layout.list_x, room_height - 30, "Need at least 8 cards to start!");
    }
}
