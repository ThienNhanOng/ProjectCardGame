function SCR_Hand_DrawFromDeck() {
    var _deck = instance_find(OBJ_Deck, 0);
    var _hand = instance_find(OBJ_Hand, 0);

    if (_deck == noone) {
        show_debug_message("OBJ_Deck not found!");
        return false;
    }
    if (_hand == noone) {
        show_debug_message("OBJ_Hand not found!");
        return false;
    }

    with (_hand) {
        if (hand_IsFull()) {
            show_debug_message("Hand is full!");
            return false;
        }
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
        _card_data = deck_CreateRuntimeCard(_card_id);
    }

    if (_card_data == undefined) return false;

    var _added = false;
    with (_hand) {
        _added = hand_AddCard(_card_data);
    }

    if (_added) {
        show_debug_message("Drew: " + _card_data.name + " HP " + string(_card_data.health)
            + "/" + string(_card_data.max_health)
            + " | Hand: " + string(_hand.hand_Count)
            + " | Deck remaining: " + string(_deck.deck_Count));
    }

    return _added;
}
