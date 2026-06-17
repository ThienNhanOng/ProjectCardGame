globalvar card_DB;
card_DB = { cards: [] };

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
        array_push(card_DB.cards, _new_cards[i]);
    }
    show_debug_message("Loaded: " + _collection.collection
        + " | Cards: " + string(array_length(_new_cards)));
}

SCR_LoadAllCollections();
