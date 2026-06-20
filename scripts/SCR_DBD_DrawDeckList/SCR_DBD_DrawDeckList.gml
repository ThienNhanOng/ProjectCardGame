function SCR_DBD_DrawDeckList() {
    var _layout = SCR_DBD_GetDeckListLayout();
    var _unique_cards = SCR_DBD_GetDeckListSummary(selected_deck);
    var _unique_count = array_length(_unique_cards);

    var _scroll = SCR_DBD_ClampDeckListScroll(_layout, SCR_DBD_GetDeckListScroll(), _unique_count);
    SCR_DBD_SetDeckListScroll(_scroll);

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_layout.list_x, 60, "=== YOUR DECK ===");

    var _total_cards = 0;
    for (var t = 0; t < _unique_count; t++) {
        _total_cards += _unique_cards[t].count;
    }

    var _prev_scissor = gpu_get_scissor();
    gpu_set_scissor(floor(_layout.list_x), floor(_layout.list_y_start),
        floor(_layout.list_w), floor(_layout.list_viewport_bottom - _layout.list_y_start));

    for (var i = 0; i < _unique_count; i++) {
        var _bounds = SCR_DBD_GetDeckListRowBounds(_layout, i, _scroll);
        if (!SCR_DBD_IsDeckListRowInViewport(_layout, _bounds)) continue;

        var _card = _unique_cards[i];
        var _line = string(i + 1) + ". " + _card.name + " x" + string(_card.count);
        var _is_hovered = SCR_DBD_IsDeckListRowHovered(_bounds);
        SCR_DBD_DrawDeckListRow(_layout, _bounds, SCR_Hand_TruncateName(_line, _layout.list_w - _layout.text_pad_x * 2), _is_hovered);
    }

    gpu_set_scissor(_prev_scissor);

    if (SCR_DBD_GetDeckListMaxScroll(_layout, _unique_count) > 0) {
        draw_set_color(c_ltgray);
        draw_set_halign(fa_right);
        draw_set_valign(fa_top);
        draw_text(_layout.list_x + _layout.list_w, _layout.list_y_start - 2, "Scroll: wheel");
        draw_set_halign(fa_left);
    }

    draw_set_color(c_yellow);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_layout.list_x, room_height - 50, "Total: " + string(_total_cards) + " / " + string(collection_GetDeckMaxSize()) + " cards");

    if (_total_cards < 8) {
        draw_set_color(c_red);
        draw_text(_layout.list_x, room_height - 30, "Need at least 8 cards to start!");
    }
}
