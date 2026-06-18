/// @desc Entry point for loading all monster JSON sets (calls load_MonsterSet on GameController)

function SCR_LoadAllMonsters() {
    load_MonsterSet("MonsterSet01.json");
    load_MonsterSet("MonsterSet02.json");
    load_MonsterSet("MonsterSet03.json");
    show_debug_message("Total enemies in DB: " + string(array_length(monster_DB.enemies)));
}
