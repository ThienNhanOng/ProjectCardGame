function collection_GetDeckMaxSize() {
    return 60;
}

function player_deck_FindCollectionEntry(_card_id) {
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (_card.id != _card_id) continue;
        if (_card.type == "spirit" || _card.type == "special_monster") return undefined;
        return _card;
    }

    var _def = collection_FindDefinition(_card_id);
    if (_def == undefined) return undefined;
    if (_def.type == "spirit" || _def.type == "special_monster") return undefined;
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
