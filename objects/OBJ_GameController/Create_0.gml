// === LOAD CARD DATABASE FROM JSON ===
var _file     = file_text_open_read("cards.json");
var _json_str = "";

while (!file_text_eof(_file)) {
    _json_str += file_text_read_string(_file);
    file_text_readln(_file);
}

file_text_close(_file);

// card_DB is now a global struct you can access anywhere
globalvar card_DB;
card_DB = json_parse(_json_str);

show_debug_message("Card DB loaded. Total cards: " 
    + string(array_length(card_DB.cards)));