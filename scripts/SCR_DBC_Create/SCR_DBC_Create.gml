function SCR_DBC_Create() {
    SCR_DBC_InitGrid();
    SCR_DBC_InitContainer();
    filter_type = "";
    search_text = "";
    search_focused = false;
    SCR_DBC_InitDeck();
    SetupPlayerCollection();
    player_deck_LoadSavedDeck();
    SCR_DBC_InitPagination();
    SCR_ExtraDeck_Init();
    SCR_DBC_LoadPage();

}
