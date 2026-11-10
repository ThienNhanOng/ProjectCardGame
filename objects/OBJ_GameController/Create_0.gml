globalvar card_DB;   // the enemy database is global.monster_DB (scr_monster_data)

if (!variable_global_exists("card_DB") || !is_struct(card_DB) || array_length(card_DB.cards) <= 0) {
    card_DB = { cards: [] };
    SCR_LoadAllCollections();
}

battle_EnsureMonsterDatabase();
collection_EnsurePlayerInitialized();
