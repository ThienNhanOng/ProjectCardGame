function SCR_DBC_LoadPage() {
    with (OBJ_CardSlot) {
        instance_destroy();
    }
    
    var _cards = global.player_collection;
    
    // --- FIX 1: Build a filtered list of cards that are actually available ---
    var _available_cards = [];
    for (var i = 0; i < array_length(_cards); i++) {
        var _card = _cards[i];
        
        // ===== ADD THIS: SKIP SPIRIT CARDS =====
        if (_card.type == "spirit" || _card.type == "special_monster") {
            continue;  // Don't show spirits in main collection
        }
        // =======================================
        
        var _in_deck = 0;
        for (var d = 0; d < array_length(selected_deck); d++) {
            if (selected_deck[d].id == _card.id) {
                _in_deck++;
            }
        }
        
        var _available = _card.owned - _in_deck;
        
        if (_available > 0) {
            // Store the card AND its available count together
            array_push(_available_cards, {
                card: _card,
                available: _available
            });
        }
    }
    
    // --- FIX 4: Clamp current_page so it can never go negative or out of bounds ---
    var _max_page = max(0, ceil(array_length(_available_cards) / cards_per_page) - 1);
    if (current_page > _max_page) current_page = _max_page;
    if (current_page < 0) current_page = 0;
    
    // --- FIX 2: Paginate over the FILTERED list, not the raw collection ---
    var _start = current_page * cards_per_page;
    var _end = min(_start + cards_per_page, array_length(_available_cards));
    
    for (var i = _start; i < _end; i++) {
        var _entry = _available_cards[i];
        
        // _pos is now sequential with no gaps
        var _pos = i - _start;
        var _col = _pos mod grid_cols_visible;
        var _row = _pos div grid_cols_visible;
        
        var _x = grid_start_x + _col * (card_w + grid_padding_x);
        var _y = grid_start_y + _row * (card_h + grid_padding_y);
        
        var _slot = instance_create_layer(_x, _y, "Instances", OBJ_CardSlot);
        _slot.card_id = _entry.card.id;
        _slot.card_data = _entry.card;
        _slot.count = _entry.available;  // copies left to add
        _slot.card_w = card_w;
        _slot.card_h = card_h;
        _slot.just_created = true;
        _slot.depth = -_x;  // ADD THIS: Rightmost cards (higher x) have lower depth (drawn on top)
    }
    
    // --- FIX 3: Expose total pages so your UI doesn't go out of bounds ---
    total_pages = ceil(array_length(_available_cards) / cards_per_page);
    if (total_pages == 0) { total_pages = 1; }
}