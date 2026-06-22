globalvar card_DB;
globalvar monster_DB;

if (!variable_global_exists("card_DB") || !is_struct(card_DB) || array_length(card_DB.cards) <= 0) {
    card_DB = { cards: [] };
    SCR_LoadAllCollections();
}

battle_EnsureMonsterDatabase();
