function SCR_DBC_LoadPage() {
    with (OBJ_CardSlot) {
        instance_destroy();
    }

    var _available_cards = SCR_DBD_BuildAvailableEntries();

    var _max_page = max(0, ceil(array_length(_available_cards) / cards_per_page) - 1);
    if (current_page > _max_page) current_page = _max_page;
    if (current_page < 0) current_page = 0;

    var _start = current_page * cards_per_page;
    var _end = min(_start + cards_per_page, array_length(_available_cards));

    for (var i = _start; i < _end; i++) {
        var _entry = _available_cards[i];

        var _pos = i - _start;
        var _col = _pos mod grid_cols_visible;
        var _row = _pos div grid_cols_visible;

        var _x = grid_start_x + _col * (card_w + grid_padding_x);
        var _y = grid_start_y + _row * (card_h + grid_padding_y);

        var _slot = instance_create_layer(_x, _y, "Instances", OBJ_CardSlot);
        _slot.card_id = _entry.card.id;
        _slot.card_data = _entry.card;
        _slot.count = _entry.available;
        _slot.card_w = card_w;
        _slot.card_h = card_h;
        _slot.depth = -_x;
    }

    total_pages = max(1, ceil(array_length(_available_cards) / cards_per_page));
}
