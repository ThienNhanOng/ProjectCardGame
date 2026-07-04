function SCR_Hand_DrawFromDeck() {
    var _deck = instance_find(OBJ_Deck, 0);
    var _hand = instance_find(OBJ_Hand, 0);

    if (_deck == noone) {
return false;
    }
    if (_hand == noone) {
return false;
    }

    with (_hand) {
        if (hand_IsFull()) {
return false;
        }
    }

    var _card_id = -1;
    with (_deck) {
        _card_id = deck_DrawCard();
    }

    if (_card_id == -1) {
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
}

    return _added;
}
