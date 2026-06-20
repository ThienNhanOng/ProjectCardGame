function SCR_LoadAllCollections() {

    card_DB.cards = [];

	load_Collection("MonsterTestset.json");
	load_Collection("TestActionset.json");
	load_Collection("TestWeaponset.json");

    show_debug_message("Total cards in DB: " + string(array_length(card_DB.cards)));

}

