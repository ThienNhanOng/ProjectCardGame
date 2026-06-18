function SCR_LoadAllCollections() {
    card_DB.cards = [];
    load_Collection("cardSet_01.json");
    load_Collection("cardSet_02.json");
    load_Collection("cardSet_TraitDemo_01_Monsters.json");
    load_Collection("cardSet_TraitDemo_02_Actions.json");
    load_MixedContent("TraitDemo_04_Mix.json");
    show_debug_message("Total cards in DB: " + string(array_length(card_DB.cards)));
}
