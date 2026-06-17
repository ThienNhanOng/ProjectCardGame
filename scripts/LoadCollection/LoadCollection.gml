function SCR_LoadAllCollections() {
    load_Collection("cardset_01.json");
    load_Collection("cardset_02.json");
    show_debug_message("Total cards in DB: " + string(array_length(card_DB.cards)));
}