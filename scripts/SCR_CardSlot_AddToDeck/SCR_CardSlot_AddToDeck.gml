function SCR_CardSlot_AddToDeck() {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
    
    if (_deckbuilder == noone) return false;
    if (array_length(_deckbuilder.selected_deck) >= 40) return false;
    
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == card_id && global.player_collection[i].owned > 0) {
            
            // Decrease owned count
            global.player_collection[i].owned--;
            
            // CRITICAL: Update the badge display
            count = global.player_collection[i].owned;
            
            // Force visual refresh
            image_blend = c_lime;
            
            // Add to deck
            var _copy = {
                id: card_data.id,
                name: card_data.name,
                type: card_data.type
            };
            array_push(_deckbuilder.selected_deck, _copy);
            
            show_debug_message("Added " + card_data.name + " | Remaining: " + string(global.player_collection[i].owned) + " | Badge: " + string(count));
            
            _deckbuilder.click_processed = true;
            
            // Only destroy when no copies left
            if (global.player_collection[i].owned <= 0) {
                instance_destroy();
                show_debug_message("Card destroyed: " + card_data.name);
            }
            
            return true;
        }
    }
    
    return false;
}