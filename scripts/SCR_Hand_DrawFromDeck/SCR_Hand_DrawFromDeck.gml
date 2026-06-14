function SCR_Hand_DrawFromDeck() {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) {
        show_debug_message("OBJ_Deck not found!");
        return false;
    }
    
    if (hand_IsFull()) {
        show_debug_message("Hand is full!");
        return false;
    }
    
    var _card_id = -1;
    with (_deck) {
        _card_id = deck_DrawCard();
    }
    
    if (_card_id == -1) {
        show_debug_message("Deck is empty!");
        return false;
    }
    
    var _card_data = undefined;
    with (_deck) {
        _card_data = deck_GetCardData(_card_id);
    }
    
    if (_card_data != undefined) {
        hand_AddCard(_card_data);
        show_debug_message("Drew: " + _card_data.name + " | Hand: " + string(hand_Count) + " | Deck remaining: " + string(_deck.deck_Count));
        return true;
    }
    
    return false;
}