function SCR_Hand_Init() {
    SCR_Hand_Create();
    //starting hand value
    for (var i = 0; i < 5; i++) {
        SCR_Hand_DrawFromDeck();
    }
    
    show_debug_message("Opening hand drawn. Hand size: " + string(hand_Count));
}