/// @desc Load enemy JSON sets into monster_DB

function monsters_EnsureDatabase() {
    if (!variable_global_exists("monster_DB") || !is_struct(global.monster_DB)) {
        global.monster_DB = { enemies: [] };
    }
}

function load_MonsterSet_ResolvePath(_filename) {
    if (file_exists(_filename)) return _filename;

    var _alts = [
        "datafiles/test set/" + _filename,
        "datafiles/" + _filename
    ];
    for (var i = 0; i < array_length(_alts); i++) {
        if (file_exists(_alts[i])) return _alts[i];
    }
    return _filename;
}

function load_MonsterSet(_filename) {
    monsters_EnsureDatabase();

    var _path = load_MonsterSet_ResolvePath(_filename);
    if (!file_exists(_path)) {
return;
    }

    var _file = file_text_open_read(_path);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _set = json_parse(_json_str);

    if (!variable_struct_exists(_set, "enemy") || !is_array(_set.enemy)) {
return;
    }

    if (!variable_struct_exists(_set, "collection") || string(_set.collection) == "") {
return;
    }

    var _new_enemies = _set.enemy;
    for (var i = 0; i < array_length(_new_enemies); i++) {
        var _src = _new_enemies[i];
        var _entry = {
            collection: _set.collection,
            enemyID: _src.enemyID,
            enemyname: _src.enemyname,
            type: _src.type,
            tag: _src.tag,
            sprite: _src.sprite,
            level: _src.level,
            enemyhealthvalue: _src.enemyhealthvalue,
            enemyattackvalue: _src.enemyattackvalue,
            enemyability: _src.enemyability
        };
        if (variable_struct_exists(_src, "animation")) {
            _entry.animation = _src.animation;
        }
        if (variable_struct_exists(_src, "elite")) {
            _entry.elite = _src.elite;
        }
        array_push(global.monster_DB.enemies, _entry);
    }

}

function load_MixedContent(_filename) {
    collection_EnsureDatabase();
    monsters_EnsureDatabase();

    if (!file_exists(_filename)) {
return;
    }

    var _file = file_text_open_read(_filename);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _data = json_parse(_json_str);
    var _card_count = 0;
    var _enemy_count = 0;

    if (variable_struct_exists(_data, "cards") && is_array(_data.cards)) {
        for (var i = 0; i < array_length(_data.cards); i++) {
            var _card = card_NormalizeDefinition(_data.cards[i]);
            _card.collection = _data.collection;
            array_push(card_DB.cards, _card);
            _card_count++;
        }
    }

    if (variable_struct_exists(_data, "enemy") && is_array(_data.enemy)) {
        for (var j = 0; j < array_length(_data.enemy); j++) {
            var _src = _data.enemy[j];
            var _entry = {
                collection: _data.collection,
                enemyID: _src.enemyID,
                enemyname: _src.enemyname,
                type: _src.type,
                tag: _src.tag,
                sprite: _src.sprite,
                level: _src.level,
                enemyhealthvalue: _src.enemyhealthvalue,
                enemyattackvalue: _src.enemyattackvalue,
                enemyability: _src.enemyability
            };
            if (variable_struct_exists(_src, "animation")) _entry.animation = _src.animation;
            if (variable_struct_exists(_src, "elite")) _entry.elite = _src.elite;
            array_push(global.monster_DB.enemies, _entry);
            _enemy_count++;
        }
    }

}

function monsters_LoadBuiltinFallback() {
    monsters_EnsureDatabase();

    array_push(global.monster_DB.enemies, {
        collection: "enemyCollection01",
        enemyID: 1,
        enemyname: "Goblin Raider",
        type: "monster",
        tag: ["Goblin", "Set1"],
        sprite: "SPR_Monsterplaceholder",
        animation: "GoblinSoldier",
        level: 1,
        enemyhealthvalue: 6,
        enemyattackvalue: 6,
        enemyability: []
    });

}

function SCR_LoadAllMonsters() {
    monsters_EnsureDatabase();
    global.monster_DB.enemies = [];

    load_MonsterSet("EnemyCollection01.json");
    load_MonsterSet("AbilityTestMonsters.json");

    if (array_length(global.monster_DB.enemies) <= 0) {
        monsters_LoadBuiltinFallback();
    }

}

function battle_EnsureMonsterDatabase() {
    monsters_EnsureDatabase();

    if (array_length(global.monster_DB.enemies) <= 0) {
        SCR_LoadAllMonsters();
    }

    if (variable_global_exists("monster_DB")) {
        monster_DB = global.monster_DB;
    }

}
