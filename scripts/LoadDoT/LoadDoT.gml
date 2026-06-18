/// @desc Load DoT type definitions from datafiles/DoT_*.json

function SCR_LoadAllDoT() {
    dot_DB = {};
    load_DoTType("DoT_burn.json");
    load_DoTType("DoT_poison.json");
    load_DoTType("DoT_electrocuted.json");
    show_debug_message("DoT types loaded: " + string(variable_struct_names_count(dot_DB)));
}

function load_DoTType(_filename) {
    if (!file_exists(_filename)) {
        show_debug_message("DoT file not found: " + _filename);
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
    if (!variable_struct_exists(_data, "dot_type")) {
        show_debug_message("DoT file missing dot_type: " + _filename);
        return;
    }

    dot_DB[$ _data.dot_type] = {
        dot_type: _data.dot_type,
        label: variable_struct_exists(_data, "label") ? _data.label : _data.dot_type,
        damage_per_tick: variable_struct_exists(_data, "damage_per_tick") ? _data.damage_per_tick : 1,
        default_duration: variable_struct_exists(_data, "default_duration") ? _data.default_duration : 3
    };

    show_debug_message("Loaded DoT: " + _data.dot_type + " (" + dot_DB[$ _data.dot_type].label + ")");
}

function dot_GetDefinition(_dot_type) {
    if (!variable_global_exists("dot_DB")) return undefined;
    if (!variable_struct_exists(dot_DB, _dot_type)) {
        show_debug_message("DoT type not found: " + _dot_type);
        return undefined;
    }
    return dot_DB[$ _dot_type];
}
