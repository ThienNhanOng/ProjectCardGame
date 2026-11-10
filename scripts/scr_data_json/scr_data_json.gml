/// @desc JSON file helpers shared by every data loader (cards, enemies, battles, world maps)

/// _s.<_key> if the struct has it, else _default (for optional JSON fields)
function struct_GetOr(_s, _key, _default) {
    if (!is_struct(_s) || !variable_struct_exists(_s, _key)) return _default;
    return variable_struct_get(_s, _key);
}

/// Read a whole text file and json_parse it. Returns undefined when the file is missing.
/// Data files may use // comments (a whole line, or after the value on a line); they're
/// dropped before parsing. A "//" inside a "string" is kept.
function data_ReadJsonFile(_path) {
    if (!file_exists(_path)) return undefined;

    var _file = file_text_open_read(_path);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += data_StripLineComment(file_text_read_string(_file)) + "\n";
        file_text_readln(_file);
    }
    file_text_close(_file);

    return json_parse(_json_str);
}

/// One line of a data file without its // comment (text inside "quotes" is left alone)
function data_StripLineComment(_line) {
    if (string_pos("//", _line) == 0) return _line;
    var _len = string_length(_line);
    var _in_string = false;
    for (var i = 1; i < _len; i++) {
        var _c = string_char_at(_line, i);
        if (_in_string) {
            if (_c == "\\") i++;                 // skip the escaped character
            else if (_c == "\"") _in_string = false;
        } else if (_c == "\"") {
            _in_string = true;
        } else if (_c == "/" && string_char_at(_line, i + 1) == "/") {
            return string_copy(_line, 1, i - 1);
        }
    }
    return _line;
}
