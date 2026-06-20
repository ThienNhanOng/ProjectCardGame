/// @desc Load player card JSON into card_DB

function collection_EnsureDatabase() {
    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) {
        card_DB = { cards: [] };
    }
}

function load_Collection(_filename) {
    collection_EnsureDatabase();

    if (!file_exists(_filename)) {
        show_debug_message("Collection not found: " + _filename);
        return;
    }

    var _file = file_text_open_read(_filename);
    var _json_str = "";
    while (!file_text_eof(_file)) {
        _json_str += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _collection = json_parse(_json_str);
    var _new_cards = _collection.cards;
    for (var i = 0; i < array_length(_new_cards); i++) {
        var _card = card_NormalizeDefinition(_new_cards[i]);
        _card.collection = _collection.collection;
        array_push(card_DB.cards, _card);
    }

    show_debug_message("Loaded: " + _collection.collection
        + " | Cards: " + string(array_length(_new_cards)));
}

function SCR_LoadAllCollections() {
    collection_EnsureDatabase();
    card_DB.cards = [];

    load_Collection("Merc_starterdeck01.json");

    show_debug_message("Total cards in DB: " + string(array_length(card_DB.cards)));
}
