/// @desc Load card JSON into card_DB (full card pool — not the same as player ownership)

function collection_EnsureDatabase() {
    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) {
        card_DB = { cards: [] };
    }
}

function load_Collection_ResolvePath(_filename) {
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

function load_Collection(_filename) {
    collection_EnsureDatabase();

    var _path = load_Collection_ResolvePath(_filename);
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

    var _collection = json_parse(_json_str);
    var _new_cards = _collection.cards;
    for (var i = 0; i < array_length(_new_cards); i++) {
        var _card = card_NormalizeDefinition(_new_cards[i]);
        _card.collection = _collection.collection;
        array_push(card_DB.cards, _card);
    }

}

function SCR_LoadAllCollections() {
    collection_EnsureDatabase();
    card_DB.cards = [];

    load_Collection("Merc_starterdeck01.json");
    load_Collection("AbilityTestCards.json");

}
