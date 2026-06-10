function SCR_CardSlot_CheckVisibility() {
    var _deckbuilder = OBJ_DeckBuilder;
    
    if (_deckbuilder == noone) {
        show_debug_message("ERROR: Cannot find OBJ_DeckBuilder!");
        return false;
    }
    
    var _container_top = _deckbuilder.container_y;
    var _container_bottom = _deckbuilder.container_y + _deckbuilder.container_h;
    
    // Debug: Print card position and container bounds
    show_debug_message("Card Y: " + string(y) + " to " + string(y + card_h));
    show_debug_message("Container: " + string(_container_top) + " to " + string(_container_bottom));
    
    if (y + card_h < _container_top || y > _container_bottom) {
        show_debug_message("Card HIDDEN - outside container");
        return false;
    }
    
    show_debug_message("Card VISIBLE");
    return true;
}