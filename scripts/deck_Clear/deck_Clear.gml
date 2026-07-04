function deck_Clear() {
    for (var i = 0; i < deck_Max; i++) {
        deck[i] = 0;
    }
    deck_Count = 0;
    deck_Head = 0;
}