globalvar card_DB;
card_DB = { cards: [] };

globalvar monster_DB;
monster_DB = { enemies: [] };

globalvar dot_DB;
dot_DB = {};

function load_Collection(filename) {
    if (!file_exists(filename)) {
        show_debug_message("Collection not found: " + filename);
        return;
    }
    var _file     = file_text_open_read(filename);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);
    var _collection = json_parse(_json_str);
    var _new_cards  = _collection.cards;
    for (var i = 0; i < array_length(_new_cards); i++) {
        array_push(card_DB.cards, card_NormalizeDefinition(_new_cards[i]));
    }
    show_debug_message("Loaded: " + _collection.collection
        + " | Cards: " + string(array_length(_new_cards)));
}

function load_MonsterSet(filename) {
    if (!file_exists(filename)) {
        show_debug_message("Monster set not found: " + filename);
        return;
    }
    var _file     = file_text_open_read(filename);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);
    var _set         = json_parse(_json_str);
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
        array_push(monster_DB.enemies, _entry);
    }
    show_debug_message("Loaded: " + _set.collection
        + " | Enemies: " + string(array_length(_new_enemies)));
}

function load_MixedContent(_filename) {
    if (!file_exists(_filename)) {
        show_debug_message("Mixed content not found: " + _filename);
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
            array_push(card_DB.cards, card_NormalizeDefinition(_data.cards[i]));
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
            array_push(monster_DB.enemies, _entry);
            _enemy_count++;
        }
    }

    show_debug_message("Loaded mix: " + _data.collection
        + " | Cards: " + string(_card_count)
        + " | Enemies: " + string(_enemy_count));
}

SCR_LoadAllCollections();
SCR_LoadAllMonsters();
SCR_LoadAllDoT();
