function SCR_CardSlot_AddToDeck() {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
    
    if (_deckbuilder == noone) return false;
    if (array_length(_deckbuilder.selected_deck) >= collection_GetDeckMaxSize()) return false;
    
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == card_id) {
            
            var _in_deck = SCR_DBD_GetDeckCount(card_id);
            var _available = collection_GetAvailableCopies(global.player_collection[i]);
            if (_available <= 0) {
                var _max = collection_GetMaxDeckCopies(global.player_collection[i]);
                var _owned = variable_struct_exists(global.player_collection[i], "owned")
                    ? global.player_collection[i].owned : 0;
                show_debug_message("No copies left for " + card_data.name
                    + " (owned " + string(_owned) + ", deck max " + string(_max)
                    + ", in deck " + string(_in_deck) + ")");
                return false;
            }
            
            // Add to deck
            var _copy = {
                id: card_data.id,
                name: card_data.name,
                type: card_data.type
            };
            array_push(_deckbuilder.selected_deck, _copy);
            SCR_DBD_ShuffleSelectedDeck();
            player_deck_PersistSelectedDeck(_deckbuilder);
            
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