function SCR_DBD_DrawDeckList() {
    var _list_x = room_width - 180;
    
    // Count duplicates in the deck
    var _deck_counts = {};
    for (var i = 0; i < array_length(selected_deck); i++) {
        var _card = selected_deck[i];
        var _id = string(_card.id);
        if (!variable_struct_exists(_deck_counts, _id)) {
            _deck_counts[$ _id] = 0;
        }
        _deck_counts[$ _id]++;
    }
    
    // Get unique cards with their counts
    var _unique_cards = [];
    var _keys = variable_struct_get_names(_deck_counts);
    var _key_count = array_length(_keys);
    for (var k = 0; k < _key_count; k += 1) {
        var _id = _keys[k];
        for (var i = 0; i < array_length(selected_deck); i++) {
            if (string(selected_deck[i].id) == _id) {
                var _card = {
                    id: selected_deck[i].id,
                    name: selected_deck[i].name,
                    type: selected_deck[i].type,
                    count: _deck_counts[$ _id]
                };
                array_push(_unique_cards, _card);
                break;
            }
        }
    }
    
    // Header
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_list_x, 60, "=== YOUR DECK ===");
    
    // Card list - reuse existing display style but with counts
    var _total_cards = 0;
    var _unique_count = array_length(_unique_cards);
    for (var i = 0; i < _unique_count; i += 1) {
        var _y = 80 + (i * 18);
        
        if (_y > room_height - 100) {
            draw_text(_list_x, _y, "... and more");
            break;
        }
        
        var _card = _unique_cards[i];
        _total_cards += _card.count;
        
        // Reuse existing format but show count like "Goblin strike x3"
        draw_text(_list_x, _y, string(i + 1) + ". " + _card.name + " x" + string(_card.count));
    }
    
    // Total counter - reuse existing
    draw_set_color(c_yellow);
    draw_text(_list_x, room_height - 50, "Total: " + string(_total_cards) + " / 40 cards");
    
    // Warning - reuse existing
    if (_total_cards < 8) {
        draw_set_color(c_red);
        draw_text(_list_x, room_height - 30, "Need at least 8 cards to start!");
    }
}