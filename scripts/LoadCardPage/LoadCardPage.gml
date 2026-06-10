function LoadCardPage() {
    // Clear existing cards
    with (OBJ_CardSlot) {
        instance_destroy();
    }
    
    var _cards = card_DB.cards;
    var _start_index = current_page * cards_per_page;
    var _end_index = min(_start_index + cards_per_page, array_length(_cards));
    
    // Create cards for current page
    for (var i = _start_index; i < _end_index; i++) {
        var _pos_in_page = i - _start_index;
        var _col = _pos_in_page mod grid_cols_visible;
        var _row = floor(_pos_in_page / grid_cols_visible);
        
        var _x = grid_start_x + _col * (card_w + grid_padding_x);
        var _y = grid_start_y + _row * (card_h + grid_padding_y);
        
        var _slot = instance_create_layer(_x, _y, "Instances", OBJ_CardSlot);
        _slot.card_id = _cards[i].id;
        _slot.card_data = _cards[i];
        _slot.count = 0;
        _slot.card_w = card_w;
        _slot.card_h = card_h;
    }
}