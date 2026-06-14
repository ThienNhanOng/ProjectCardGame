function SCR_Hand_Create() {
	hand_X = 40;
	hand_Y = 615;
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