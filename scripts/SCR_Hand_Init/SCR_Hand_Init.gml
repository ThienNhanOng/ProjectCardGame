// ===== HAND INITIALIZATION SCRIPT =====
// Call this in OBJ_Hand Create Event: SCR_Hand_Create();

function SCR_Hand_Create() {
    // ===== HAND PROPERTIES =====
    hand_X = 100;
    hand_Y = 600;
    hand_Spacing = 85;
    hand_MaxSize = 7;
    hand_Count = 0;
    
    // Card slots (stores card data objects)
    hand = [];
    
    // Initialize empty hand
    for (var i = 0; i < hand_MaxSize; i++) {
        hand[i] = undefined;
    }
}

// ===== HAND FUNCTIONS =====
function hand_AddCard(_card_data) {
    if (hand_Count >= hand_MaxSize) {
        show_debug_message("Hand is full! Cannot add card " + _card_data.name);
        return false;
    }
    hand[hand_Count] = _card_data;
    hand_Count++;
    show_debug_message("Added to hand: " + _card_data.name + " (Hand size: " + string(hand_Count) + ")");
    return true;
}

function hand_RemoveCard(_index) {
    if (_index >= hand_Count || _index < 0) {
        show_debug_message("Invalid hand index: " + string(_index));
        return undefined;
    }
    var _card = hand[_index];
    
    // Shift remaining cards left
    for (var i = _index; i < hand_Count - 1; i++) {
        hand[i] = hand[i + 1];
    }
    hand[hand_Count - 1] = undefined;
    hand_Count--;
    
    show_debug_message("Removed from hand: " + _card.name + " (Hand size: " + string(hand_Count) + ")");
    return _card;
}

function hand_GetCard(_index) {
    if (_index >= 0 && _index < hand_Count) {
        return hand[_index];
    }
    return undefined;
}

function hand_GetCount() {
    return hand_Count;
}

function hand_IsFull() {
    return hand_Count >= hand_MaxSize;
}

function hand_IsEmpty() {
    return hand_Count <= 0;
}

function hand_Clear() {
    for (var i = 0; i < hand_MaxSize; i++) {
        hand[i] = undefined;
    }
    hand_Count = 0;
    show_debug_message("Hand cleared");
}

// Debug: Print all cards in hand
function hand_DebugPrint() {
    show_debug_message("=== HAND CONTENTS ===");
    for (var i = 0; i < hand_Count; i++) {
        if (hand[i] != undefined) {
            show_debug_message("Slot " + string(i) + ": " + hand[i].name + " (ID: " + string(hand[i].id) + ")");
        }
    }
    show_debug_message("Total cards: " + string(hand_Count));
}