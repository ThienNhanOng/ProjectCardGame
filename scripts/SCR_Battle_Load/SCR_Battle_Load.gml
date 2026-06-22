/// @desc Load battle wave configs — single files and battleset collections

function battle_NormalizeCollectionName(_collection) {
    var _name = string(_collection);
    switch (_name) {
        case "enemySet_01":
        case "enemySet_02":
        case "enemySet_03":
        case "enemyGoblins_01":
        case "enemyOrcs_01":
            return "enemyCollection01";
        default:
            return _name;
    }
}

function battle_NormalizeWaveConfig(_data) {
    var _wave = [];
    if (variable_struct_exists(_data, "wave") && is_array(_data.wave)) {
        for (var i = 0; i < array_length(_data.wave); i++) {
            array_push(_wave, {
                collection: battle_NormalizeCollectionName(_data.wave[i].collection),
                enemyID: floor(_data.wave[i].enemyID)
            });
        }
    }

    return {
        battle: _data.battle,
        active_slots: _data.active_slots,
        wave: _wave
    };
}

function battle_LoadConfig(_filename) {
    if (!file_exists(_filename)) {
        show_debug_message("Battle config not found: " + _filename);
        return undefined;
    }

    var _file     = file_text_open_read(_filename);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _data = json_parse(_json_str);
    var _config = battle_NormalizeWaveConfig(_data);

    show_debug_message("Loaded battle: " + string(_config.battle)
        + " | Active slots: " + string(_config.active_slots)
        + " | Wave size: " + string(array_length(_config.wave)));

    return _config;
}

function battle_LoadBattleset(_filename) {
    if (!variable_global_exists("battleset_cache")) {
        global.battleset_cache = {};
    }

    if (variable_struct_exists(global.battleset_cache, _filename)) {
        return global.battleset_cache[$ _filename];
    }

    if (!file_exists(_filename)) {
        show_debug_message("Battleset not found: " + _filename);
        return undefined;
    }

    var _file = file_text_open_read(_filename);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _data = json_parse(_json_str);
    var _battles = {};

    if (variable_struct_exists(_data, "battles") && is_array(_data.battles)) {
        for (var i = 0; i < array_length(_data.battles); i++) {
            var _entry = battle_NormalizeWaveConfig(_data.battles[i]);
            _battles[$ string(_entry.battle)] = _entry;
        }
    }

    var _set = { file: _filename, battles: _battles };
    global.battleset_cache[$ _filename] = _set;

    show_debug_message("Loaded battleset " + _filename
        + " | Battles: " + string(variable_struct_names_count(_battles)));
    return _set;
}

function battle_GetBattlesetBattle(_battleset_file, _battle_id) {
    var _set = battle_LoadBattleset(_battleset_file);
    if (_set == undefined) return undefined;

    var _key = string(_battle_id);
    if (!variable_struct_exists(_set.battles, _key)) {
        show_debug_message("Battle not found in battleset: " + _key);
        return undefined;
    }

    return _set.battles[$ _key];
}
