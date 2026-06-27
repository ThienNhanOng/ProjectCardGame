function SCR_DBD_DrawDeckList() {
    var _layout = SCR_DBD_GetDeckListLayout();
    var _rows = SCR_DBD_BuildDeckListRows(selected_deck);

    var _scroll = SCR_DBD_ClampDeckListScroll(_layout, SCR_DBD_GetDeckListScroll(), _rows);
    SCR_DBD_SetDeckListScroll(_scroll);

    var _panel_x1 = _layout.list_x - 6;
    var _panel_y1 = 54;
    var _panel_x2 = _layout.list_x + _layout.list_w + 6;
    var _panel_y2 = _layout.list_viewport_bottom + 6;

    draw_set_color(make_color_rgb(110, 110, 115));
    draw_rectangle(_panel_x1, _panel_y1, _panel_x2, _panel_y2, true);

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_layout.list_x, 60, "=== YOUR DECK ===");

    var _total_cards = array_length(selected_deck);

    var _prev_scissor = gpu_get_scissor();
    gpu_set_scissor(floor(_layout.list_x), floor(_layout.list_y_start),
        floor(_layout.list_w), floor(_layout.list_viewport_bottom - _layout.list_y_start));

    var _card_index = 0;
    for (var i = 0; i < array_length(_rows); i++) {
        var _bounds = SCR_DBD_GetDeckListRowBounds(_layout, _rows, i, _scroll);
        if (!SCR_DBD_IsDeckListRowInViewport(_layout, _bounds)) continue;

        if (_rows[i].kind == "header") {
            _card_index = 0;
            SCR_DBD_DrawDeckListSectionHeader(_layout, _bounds, _rows[i].label, _rows[i].color);
            continue;
        }

        _card_index++;
        var _line = string(_card_index) + ". " + _rows[i].name + " x" + string(_rows[i].count);
        var _is_hovered = SCR_DBD_IsDeckListRowHovered(_bounds);
        SCR_DBD_DrawDeckListRow(_layout, _bounds, SCR_Hand_TruncateName(_line, _layout.list_w - _layout.text_pad_x * 2), _is_hovered);
    }

    gpu_set_scissor(_prev_scissor);

    if (SCR_DBD_GetDeckListMaxScroll(_layout, _rows) > 0) {
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
