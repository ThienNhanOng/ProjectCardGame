function SCR_DBC_LoadPage() {
    // Clear all existing card slots
    with (OBJ_CardSlot) {
        instance_destroy();
    }
    
    var _cards = global.player_collection;
    var _start = current_page * cards_per_page;
    var _end = min(_start + cards_per_page, array_length(_cards));
    
    for (var i = _start; i < _end; i++) {
        var _card = _cards[i];
        
        // Count how many of this card are already in deck
        var _in_deck = 0;
        for (var d = 0; d < array_length(selected_deck); d++) {
            if (selected_deck[d].id == _card.id) {
                _in_deck++;
            }
        }
        
        // Calculate available copies (owned - in_deck)
        var _available = _card.owned - _in_deck;
        
        // IMPORTANT: Only show if available > 0
        // DO NOT use IsCardInDeck here - that would hide cards that still have copies left
        if (_available > 0) {
            var _pos = i - _start;
            var _col = _pos mod grid_cols_visible;
            var _row = _pos div grid_cols_visible;
            
            var _x = grid_start_x + _col * (card_w + grid_padding_x);
            var _y = grid_start_y + _row * (card_h + grid_padding_y);
            
            var _slot = instance_create_layer(_x, _y, "Instances", OBJ_CardSlot);
            _slot.card_id = _card.id;
            _slot.card_data = _card;
            _slot.count = _available;
            _slot.card_w = card_w;
            _slot.card_h = card_h;
            _slot.just_created = true;
        }
    }
}