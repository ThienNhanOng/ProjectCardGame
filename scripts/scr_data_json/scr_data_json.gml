/// @desc JSON file helpers shared by every data loader (cards, enemies, battles, world maps)

/// Read a whole text file and json_parse it. Returns undefined when the file is missing.
function data_ReadJsonFile(_path) {
    if (!file_exists(_path)) return undefined;

    var _file = file_text_open_read(_path);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    return json_parse(_json_str);
}
