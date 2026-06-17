/// @description Count how many of a card are in the deck
function SCR_DBD_GetDeckCount(_card_id) {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
    if (_deckbuilder == noone) return 0;
    
    var _count = 0;
    for (var i = 0; i < array_length(_deckbuilder.selected_deck); i++) {
        if (_deckbuilder.selected_deck[i].id == _card_id) {
            _count++;
        }
    }
    return _count;
}

/// @description Get collection cards that have available copies (owned > in_deck)
function SCR_DBD_GetAvailableCards() {
    var _available = [];
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        var _in_deck = SCR_DBD_GetDeckCount(_card.id);
        
        // Only include if there are available copies
        if (_card.owned > _in_deck) {
            array_push(_available, _card);
        }
    }
    return _available;
}

/// @description Rebuild the card grid with available cards only (no holes!)
function SCR_DBD_RebuildGrid() {
    // Get the deck builder instance
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return;
    
    // Use the builder's variables
    var _cards_per_page = _builder.cards_per_page;
    var _current_page = _builder.current_page;
    var _grid_cols_visible = _builder.grid_cols_visible;
    var _grid_start_x = _builder.grid_start_x;
    var _grid_start_y = _builder.grid_start_y;
    var _card_w = _builder.card_w;
    var _card_h = _builder.card_h;
    var _grid_padding_x = _builder.grid_padding_x;
    var _grid_padding_y = _builder.grid_padding_y;
    
    // Get available cards
    var _available = SCR_DBD_GetAvailableCards();
    
    // Update total pages
    var _total_pages = ceil(array_length(_available) / _cards_per_page);
    if (_total_pages < 1) _total_pages = 1;
    if (_current_page >= _total_pages) _current_page = _total_pages - 1;
    if (_current_page < 0) _current_page = 0;
    
    // Update the builder's current page
    _builder.current_page = _current_page;
    
    var _start = _current_page * _cards_per_page;
    var _end = min(_start + _cards_per_page, array_length(_available));
    
    // Destroy all existing card slots
    with (OBJ_CardSlot) {
        instance_destroy();
    }
    
    // Create new card slots for visible cards
    for (var i = _start; i < _end; i++) {
        var _card_data = _available[i];
        var _slot_index = i - _start;
        var _row = _slot_index div _grid_cols_visible;
        var _col = _slot_index mod _grid_cols_visible;
        var _cx = _grid_start_x + _col * (_card_w + _grid_padding_x);
        var _cy = _grid_start_y + _row * (_card_h + _grid_padding_y);
        
        // Create card slot instance
        var _slot = instance_create_layer(_cx, _cy, "Instances", OBJ_CardSlot);
        
        // Initialize the card slot
        with (_slot) {
            SCR_CardSlotCreate(_card_data.id, _card_data, _card_data.owned - SCR_DBD_GetDeckCount(_card_data.id), _card_w, _card_h);
            x = _cx;
            y = _cy;
        }
    }
}