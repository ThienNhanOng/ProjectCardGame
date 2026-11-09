/// @desc OBJ_Hand — hand storage and drawing from the deck

function SCR_Hand_Create() {
	hand_X = 40;
	hand_Y = 618;   // resting card centre in the bottom bar
	hand_Spacing = 85;
	//max cards in hand
	hand_MaxSize = 40;
    hand_Count = 0;
    hand = [];
    for (var i = 0; i < hand_MaxSize; i++) {
        hand[i] = undefined;
    }
}

function hand_AddCard(_card_data) {
    if (hand_Count >= hand_MaxSize) return false;
    hand[hand_Count] = _card_data;
    hand_Count++;
    return true;
}

function hand_RemoveCard(_index) {
    if (_index >= hand_Count || _index < 0) return undefined;
    var _card = hand[_index];
    for (var i = _index; i < hand_Count - 1; i++) {
        hand[i] = hand[i + 1];
    }
    hand[hand_Count - 1] = undefined;
    hand_Count--;
    return _card;
}

function hand_GetCard(_index) {
    if (_index >= 0 && _index < hand_Count) return hand[_index];
    return undefined;
}

function hand_GetCount() { return hand_Count; }

function hand_IsFull() { return hand_Count >= hand_MaxSize; }

function hand_IsEmpty() { return hand_Count <= 0; }

function hand_Clear() {
    for (var i = 0; i < hand_MaxSize; i++) {
        hand[i] = undefined;
    }
    hand_Count = 0;
}

function SCR_Hand_Init() {
    SCR_Hand_Create();

    for (var i = 0; i < 5; i++) {
        SCR_Hand_DrawFromDeck();
    }

}

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
        battle_SpiritShuffle_OnDeckEmpty();
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

function SCR_Hand_GetSprite(_card) {
    // the card's own art (JSON "sprite") when it names a real sprite
    if (variable_struct_exists(_card, "sprite") && is_string(_card.sprite) && _card.sprite != "") {
        var _own = asset_get_index(_card.sprite);
        if (_own != -1 && asset_get_type(_card.sprite) == asset_sprite) return _own;
    }
    var _spr = SPR_Monsterplaceholder;
    switch (_card.type) {
        case "monster":
        case "spirit":
        case "special_monster":
            _spr = SPR_Monsterplaceholder;
            break;
        case "weapon":
            _spr = SPR_Weaponplaceholder;
            break;
        case "action":
            _spr = SPR_Actionplaceholder;
            break;
    }
    return _spr;
}
