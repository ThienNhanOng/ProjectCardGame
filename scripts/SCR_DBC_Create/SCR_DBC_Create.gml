function SCR_DBC_Create() {
    SCR_DBC_InitGrid();
    SCR_DBC_InitContainer();
    SCR_DBC_InitPagination();
    SCR_DBC_InitDeck();
    SetupTestCollection();  
    SCR_DBC_LoadPage();
    
    show_debug_message("DeckBuilder Created");
}