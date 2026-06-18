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

/// @description Whether a card matches the active type/search filters
function SCR_DBD_CardMatchesFilter(_card, _filter_type, _search_text) {
    if (_filter_type != undefined && _filter_type != "" && _filter_type != "all") {
        if (_card.type != _filter_type) return false;
    }

    if (_search_text == undefined || _search_text == "") return true;

    var _query = string_lower(string_trim(_search_text));
    if (_query == "") return true;

    if (string_pos(_query, string_lower(_card.name)) > 0) return true;

    if (variable_struct_exists(_card, "tag") && is_array(_card.tag)) {
        for (var t = 0; t < array_length(_card.tag); t++) {
            if (string_pos(_query, string_lower(_card.tag[t])) > 0) return true;
        }
    }

    return false;
}

/// @description Available collection entries respecting deck, type filter, and search
function SCR_DBD_BuildAvailableEntries() {
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    var _filter_type = (_builder != noone) ? _builder.filter_type : "";
    var _search_text = (_builder != noone) ? _builder.search_text : "";

    var _entries = [];
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];

        if (_card.type == "spirit" || _card.type == "special_monster") continue;
        if (!SCR_DBD_CardMatchesFilter(_card, _filter_type, _search_text)) continue;

        var _in_deck = SCR_DBD_GetDeckCount(_card.id);
        var _available = _card.owned - _in_deck;
        if (_available > 0) {
            array_push(_entries, {
                card: _card,
                available: _available
            });
        }
    }
    return _entries;
}

/// @description Get collection cards that have available copies (owned > in_deck)
/// EXCLUDES spirit and special_monster cards from main deck collection
function SCR_DBD_GetAvailableCards() {
    var _entries = SCR_DBD_BuildAvailableEntries();
    var _available = [];
    for (var i = 0; i < array_length(_entries); i++) {
        array_push(_available, _entries[i].card);
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

function SCR_DBD_GetDeckListLayout() {
    return {
        list_x: room_width - 300,
        list_w: 270,
        list_y_start: 80,
        line_h: 22,
        line_gap: 4,
        text_pad_x: 8
    };
}

function SCR_DBD_GetDeckListRowBounds(_layout, _index) {
    var _y = _layout.list_y_start + (_index * (_layout.line_h + _layout.line_gap));
    return {
        x: _layout.list_x,
        y: _y,
        w: _layout.list_w,
        h: _layout.line_h
    };
}

function SCR_DBD_IsDeckListRowHovered(_bounds) {
    var _mx = mouse_x;
    var _my = mouse_y;
    return (_mx >= _bounds.x && _mx < _bounds.x + _bounds.w
        && _my >= _bounds.y && _my < _bounds.y + _bounds.h);
}

function SCR_DBD_DrawDeckListRow(_layout, _bounds, _text, _is_hovered) {
    var _x1 = _bounds.x;
    var _y1 = _bounds.y;
    var _x2 = _bounds.x + _bounds.w;
    var _y2 = _bounds.y + _bounds.h;

    draw_set_alpha(_is_hovered ? 0.75 : 0.45);
    draw_set_color(_is_hovered ? make_color_rgb(90, 90, 95) : make_color_rgb(55, 55, 60));
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_alpha(1);

    draw_set_color(_is_hovered ? c_yellow : make_color_rgb(110, 110, 115));
    draw_rectangle(_x1, _y1, _x2, _y2, true);

    draw_set_color(_is_hovered ? c_white : c_ltgray);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(_x1 + _layout.text_pad_x, _y1 + (_bounds.h * 0.5), _text);
}

/// @description Unique deck entries with copy counts (matches deck list draw order)
function SCR_DBD_GetDeckListSummary(_selected_deck) {
    var _deck_counts = {};
    for (var i = 0; i < array_length(_selected_deck); i++) {
        var _id = string(_selected_deck[i].id);
        if (!variable_struct_exists(_deck_counts, _id)) {
            _deck_counts[$ _id] = 0;
        }
        _deck_counts[$ _id]++;
    }

    var _unique_cards = [];
    var _keys = variable_struct_get_names(_deck_counts);
    for (var k = 0; k < array_length(_keys); k++) {
        var _id = _keys[k];
        for (var i = 0; i < array_length(_selected_deck); i++) {
            if (string(_selected_deck[i].id) == _id) {
                array_push(_unique_cards, {
                    id: _selected_deck[i].id,
                    name: _selected_deck[i].name,
                    type: _selected_deck[i].type,
                    count: _deck_counts[$ _id]
                });
                break;
            }
        }
    }
    return _unique_cards;
}

/// @description Refresh the visible collection grid (same path as page load)
function SCR_DBD_RebuildGrid() {
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return;

    with (_builder) {
        SCR_DBC_LoadPage();
    }
}
