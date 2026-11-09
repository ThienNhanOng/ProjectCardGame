/// @desc OBJ_DeckBuilder Create — container, grid, pagination, saved deck

function SCR_DBC_Create() {
    SCR_DBC_InitGrid();
    SCR_DBC_InitContainer();
    filter_type = "";
    search_text = "";
    search_focused = false;
    SCR_DBC_InitDeck();
    SetupPlayerCollection();
    player_deck_LoadSavedDeck();
    SCR_DBC_InitPagination();
    SCR_ExtraDeck_Init();
    SCR_DBC_LoadPage();

}

function SCR_DBC_InitContainer() {
    container_x = grid_start_x - 10;
    container_y = grid_start_y - 10;
    container_w = grid_cols_visible * (card_w + grid_padding_x) + 20;
    container_h = grid_rows_visible * (card_h + grid_padding_y) + 20;
}

function collection_GetDeckMaxSize() {
    return 60;
}

function player_deck_FindCollectionEntry(_card_id) {
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (_card.id != _card_id) continue;
        if (card_IsSpiritType(_card)) return undefined;
        return _card;
    }

    var _def = collection_FindDefinition(_card_id);
    if (_def == undefined) return undefined;
    if (card_IsSpiritType(_def)) return undefined;
    return _def;
}

function player_deck_CountId(_ids, _card_id) {
    var _count = 0;
    for (var i = 0; i < array_length(_ids); i++) {
        if (_ids[i] == _card_id) _count++;
    }
    return _count;
}

/// @desc Load saved main deck into selected_deck (empty if nothing saved yet)
function player_deck_LoadSavedDeck() {
    battle_MigrateLegacyDeckSources();

    var _source = battle_GetDeckSourceCopy();
    if (array_length(_source) <= 0) return;

    var _loaded_ids = [];
    for (var i = 0; i < array_length(_source); i++) {
        var _id = floor(_source[i]);
        if (_id <= 0) continue;

        var _coll = player_deck_FindCollectionEntry(_id);
        if (_coll == undefined) continue;
        if (player_deck_CountId(_loaded_ids, _id) >= collection_GetEffectiveOwned(_coll)) continue;

        array_push(_loaded_ids, _id);
        array_push(selected_deck, {
            id: _coll.id,
            name: _coll.name,
            type: _coll.type
        });
    }

    if (array_length(_loaded_ids) != array_length(_source)) {
        battle_SaveDeckSources(_loaded_ids, battle_GetExtraDeckSourceCopy());
    }
}

function player_deck_SaveSelectedDeckIds(_builder = undefined) {
    if (_builder == undefined) _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return [];

    var _ids = [];
    if (!variable_instance_exists(_builder, "selected_deck")
        || !is_array(_builder.selected_deck)) {
        return _ids;
    }

    for (var i = 0; i < array_length(_builder.selected_deck); i++) {
        array_push(_ids, _builder.selected_deck[i].id);
    }
    return _ids;
}

/// @desc Write selected_deck to global.battle_deck_source (main deck singleton)
function player_deck_PersistSelectedDeck(_builder = undefined) {
    battle_SaveDeckSources(
        player_deck_SaveSelectedDeckIds(_builder),
        battle_GetExtraDeckSourceCopy()
    );
}

function SCR_DBC_InitDeck() {
    selected_deck = [];
    deck_list_scroll = 0;
}

function SCR_DBC_InitGrid() {
    grid_cols_visible = 3;
    grid_rows_visible = 4;
    card_w = 85;
    card_h = 115;
    grid_padding_x = 30;
    grid_padding_y = 20;
    grid_start_x = 60;
    grid_start_y = 60;
}

function SCR_DBC_InitPagination() {
    current_page = 0;
    cards_per_page = grid_cols_visible * grid_rows_visible;
    total_pages = SCR_DBD_GetCollectionPageCount(cards_per_page);
}

function SCR_DBC_LoadPage() {
    with (OBJ_CardSlot) {
        instance_destroy();
    }

    var _available_cards = SCR_DBD_BuildAvailableEntries();

    var _max_page = max(0, ceil(array_length(_available_cards) / cards_per_page) - 1);
    if (current_page > _max_page) current_page = _max_page;
    if (current_page < 0) current_page = 0;

    var _start = current_page * cards_per_page;
    var _end = min(_start + cards_per_page, array_length(_available_cards));

    for (var i = _start; i < _end; i++) {
        var _entry = _available_cards[i];

        var _pos = i - _start;
        var _col = _pos mod grid_cols_visible;
        var _row = _pos div grid_cols_visible;

        var _x = grid_start_x + _col * (card_w + grid_padding_x);
        var _y = grid_start_y + _row * (card_h + grid_padding_y);

        var _slot = instance_create_layer(_x, _y, "Instances", OBJ_CardSlot);
        _slot.card_id = _entry.card.id;
        _slot.card_data = _entry.card;
        _slot.count = _entry.available;
        _slot.card_w = card_w;
        _slot.card_h = card_h;
        _slot.depth = -_x;
    }

    total_pages = max(1, ceil(array_length(_available_cards) / cards_per_page));
}
