function SCR_CardSlot_AddToDeck() {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
    
    if (_deckbuilder == noone) return false;
    if (array_length(_deckbuilder.selected_deck) >= 40) return false;
    
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == card_id) {
            
            // Count how many already in deck
            var _in_deck = 0;
            for (var d = 0; d < array_length(_deckbuilder.selected_deck); d++) {
                if (_deckbuilder.selected_deck[d].id == card_id) {
                    _in_deck++;
                }
            }
            
            // Check available without touching owned
            var _available = global.player_collection[i].owned - _in_deck;
            if (_available <= 0) return false;
            
            // Add to deck
            var _copy = {
                id: card_data.id,
                name: card_data.name,
                type: card_data.type
            };
            array_push(_deckbuilder.selected_deck, _copy);
            
            // Update badge display (available after this add)
            count = _available - 1;
            image_blend = c_lime;
            
            show_debug_message("Added " + card_data.name + " | Remaining: " + string(_available - 1));
            
            _deckbuilder.click_processed = true;
            
            // Destroy slot only when no copies left to add
            if (_available - 1 <= 0) {
                instance_destroy();
                show_debug_message("Card slot destroyed: " + card_data.name);
            }
            
            // REBUILD THE GRID - fills any holes and updates the collection
            SCR_DBD_RebuildGrid();
            
            return true;
        }
    }
    
    return false;
}