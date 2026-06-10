function SCR_CardSlot_AddToDeck() {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
    
    if (_deckbuilder != noone) {
        if (array_length(_deckbuilder.selected_deck) < 40) {
            array_push(_deckbuilder.selected_deck, card_data);
            return true;
        }
    }
    return false;
}