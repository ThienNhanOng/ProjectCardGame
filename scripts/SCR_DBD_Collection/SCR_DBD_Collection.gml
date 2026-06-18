/// @description Count how many of a card are in the deck
function SCR_DBD_GetDeckCount(_card_id) {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
    if (_deckbuilder == noone) return 0;

    var _count = 0;
    for (var i = 0; i < array_length(_deckbuilder.selected_deck); i++) {
        if (_deckbuilder.selected_deck[i].id == _card_id) {
            _count++;
        }
    }
    return _count;
}

/// @description Get collection cards that have available copies (owned > in_deck)
/// EXCLUDES spirit and special_monster cards from main deck collection
function SCR_DBD_GetAvailableCards() {
    var _available = [];
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];

        if (_card.type == "spirit" || _card.type == "special_monster") continue;

        var _in_deck = SCR_DBD_GetDeckCount(_card.id);
        if (_card.owned > _in_deck) {
            array_push(_available, _card);
        }
    }
    return _available;
}

function SCR_DBD_GetCollectionPageCount(_cards_per_page) {
    if (_cards_per_page <= 0) _cards_per_page = 1;
    return max(1, ceil(array_length(SCR_DBD_GetAvailableCards()) / _cards_per_page));
}

/// @description Get spirit cards for extra deck (spirit owned)
function SCR_DBD_GetSpiritCards() {
    var _spirits = [];
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (_card.type == "spirit" || _card.type == "special_monster") {
            array_push(_spirits, _card);
        }
    }
    return _spirits;
}

/// @description Refresh the visible collection grid (same path as page load)
function SCR_DBD_RebuildGrid() {
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return;

    with (_builder) {
        SCR_DBC_LoadPage();
    }
}
