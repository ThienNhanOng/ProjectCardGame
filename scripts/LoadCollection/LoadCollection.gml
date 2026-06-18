function SCR_LoadAllCollections() {
    card_DB.cards = [];
    load_Collection("cardSet_01.json");
    show_debug_message("Total cards in DB: " + string(array_length(card_DB.cards)));
}
