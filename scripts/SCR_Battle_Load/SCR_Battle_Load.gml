/// @desc Load a battle wave config JSON (active slots + ordered spawn queue)

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
    var _wave = [];

    for (var i = 0; i < array_length(_data.wave); i++) {
        array_push(_wave, {
            collection: _data.wave[i].collection,
            enemyID: _data.wave[i].enemyID
        });
    }

    show_debug_message("Loaded battle: " + _data.battle
        + " | Active slots: " + string(_data.active_slots)
        + " | Wave size: " + string(array_length(_wave)));

    return {
        battle: _data.battle,
        active_slots: _data.active_slots,
        wave: _wave
    };
}
