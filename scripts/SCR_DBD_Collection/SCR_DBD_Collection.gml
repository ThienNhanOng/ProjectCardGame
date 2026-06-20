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

        var _available = collection_GetAvailableCopies(_card);
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
        if (_card.type != "spirit" && _card.type != "special_monster") continue;
        if (!variable_struct_exists(_card, "owned") || _card.owned <= 0) continue;
        array_push(_spirits, _card);
    }
    return _spirits;
}

function SCR_DBD_ShuffleSelectedDeck() {
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return;

    with (_builder) {
        var _len = array_length(selected_deck);
        for (var i = _len - 1; i > 0; i--) {
            var _j = irandom(i);
            var _temp = selected_deck[i];
            selected_deck[i] = selected_deck[_j];
            selected_deck[_j] = _temp;
        }
    }
}

function SCR_DBD_GetDeckListLayout() {
    return {
        list_x: room_width - 300,
        list_w: 270,
        list_y_start: 80,
        list_viewport_bottom: 550,
        line_h: 22,
        line_gap: 4,
        text_pad_x: 8
    };
}

function SCR_DBD_GetDeckListRowStep(_layout) {
    return _layout.line_h + _layout.line_gap;
}

function SCR_DBD_GetDeckListScroll() {
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return 0;

    var _scroll = 0;
    with (_builder) _scroll = deck_list_scroll;
    return _scroll;
}

function SCR_DBD_SetDeckListScroll(_scroll) {
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return;

    with (_builder) deck_list_scroll = _scroll;
}

function SCR_DBD_GetDeckListContentHeight(_layout, _entry_count) {
    return _entry_count * SCR_DBD_GetDeckListRowStep(_layout);
}

function SCR_DBD_GetDeckListMaxScroll(_layout, _entry_count) {
    var _viewport_h = _layout.list_viewport_bottom - _layout.list_y_start;
    var _content_h = SCR_DBD_GetDeckListContentHeight(_layout, _entry_count);
    return max(0, _content_h - _viewport_h);
}

function SCR_DBD_ClampDeckListScroll(_layout, _scroll, _entry_count) {
    return clamp(_scroll, 0, SCR_DBD_GetDeckListMaxScroll(_layout, _entry_count));
}

function SCR_DBD_IsMouseOverDeckList(_layout) {
    return (mouse_x >= _layout.list_x && mouse_x < _layout.list_x + _layout.list_w
        && mouse_y >= _layout.list_y_start && mouse_y < _layout.list_viewport_bottom);
}

function SCR_DBD_IsDeckListRowInViewport(_layout, _bounds) {
    return (_bounds.y + _bounds.h > _layout.list_y_start && _bounds.y < _layout.list_viewport_bottom);
}

function SCR_DBD_GetDeckListRowBounds(_layout, _index, _scroll = undefined) {
    if (_scroll == undefined) _scroll = SCR_DBD_GetDeckListScroll();
    var _y = _layout.list_y_start + (_index * SCR_DBD_GetDeckListRowStep(_layout)) - _scroll;
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

function SCR_DBD_GetPreviewPanelLayout() {
    var _list = SCR_DBD_GetDeckListLayout();
    var _x1 = extra_x + extra_w + 10;
    var _x2 = _list.list_x - 10;
    return {
        x: _x1,
        y: container_y,
        w: max(160, _x2 - _x1),
        h: container_h
    };
}

function SCR_DBD_ResolveCardDefinition(_card_id) {
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == _card_id) {
            return global.player_collection[i];
        }
    }
    return collection_FindDefinition(_card_id);
}

function SCR_DBD_FormatCardTags(_card) {
    if (_card == undefined) return "—";
    if (!variable_struct_exists(_card, "tag") || !is_array(_card.tag) || array_length(_card.tag) <= 0) {
        return "—";
    }

    var _text = _card.tag[0];
    for (var i = 1; i < array_length(_card.tag); i++) {
        _text += ", " + _card.tag[i];
    }
    return _text;
}

function SCR_DBD_AppendAttackBuffSummaryLines(_lines, _card, _column = -1) {
    var _buff = card_GetAttackBuff(_card);
    if (_buff <= 0) return _lines;

    var _filtered = [];
    for (var i = 0; i < array_length(_lines); i++) {
        var _line = _lines[i];
        if (string_copy(_line, 1, 8) == "Attack: ") continue;
        if (string_copy(_line, 1, 5) == "ATK: ") continue;
        if (string_copy(_line, 1, 10) == "ATK buff: ") continue;
        array_push(_filtered, _line);
    }

    array_push(_filtered, "ATK buff: +" + string(_buff));
    array_push(_filtered, "Attack: " + string(battle_GetPlayerMonsterSummaryAttack(_card, _column)));
    return _filtered;
}

function SCR_DBD_GetCardSummaryLines(_card) {
    var _lines = [];
    if (_card == undefined) return _lines;

    var _type_text = _card.type;
    if (_type_text == "special_monster") _type_text = "spirit";
    array_push(_lines, "Type: " + _type_text);

    var _tier = card_GetTierLabel(_card);
    if (_tier != "") array_push(_lines, _tier);

    if (_card.type == "monster" || _card.type == "spirit" || _card.type == "special_monster") {
        if (variable_struct_exists(_card, "health")) {
            array_push(_lines, "HP: " + string(_card.health));
        }
        if (_card.type == "spirit" || _card.type == "special_monster") {
            var _spirit_atk = battle_GetMonsterStrikeAmount(_card);
            if (_spirit_atk > 0) array_push(_lines, "Attack: " + string(_spirit_atk));
            if (variable_struct_exists(_card, "owned")) {
                array_push(_lines, "Owned: " + string(_card.owned));
            }
        }
    }

    if (_card.type == "weapon") {
        var _atk = variable_struct_exists(_card, "attack") ? _card.attack : 0;
        if (_atk <= 0) {
            var _attack_trait = trait_FindFirst(trait_GetFromCard(_card), "attack");
            if (_attack_trait != undefined && _attack_trait.amount > 0) {
                _atk = _attack_trait.amount;
            }
        }
        array_push(_lines, "Attack: " + string(_atk));

        var _usage = weapon_GetAttackRecursion(_card);
        if (_usage > 1) {
            array_push(_lines, "Usage: " + string(_usage));
        }
    }

    var _cost_text = card_FormatAllCosts(_card);
    if (_cost_text != "") {
        array_push(_lines, "Cost: " + _cost_text);
    }

    return _lines;
}

function SCR_DBD_FormatTraitLine(_trait) {
    if (_trait == undefined) return "None";

    var _text = trait_GetDisplayText(_trait);

    if (_trait.type == "add" && _trait.card_id >= 0) {
        _text = "Add to hand " + deck_GetCardName(_trait.card_id);
    } else if (_trait.type == "add_deck" && _trait.card_id >= 0) {
        _text = "Add to deck " + deck_GetCardName(_trait.card_id);
    } else if (_trait.type == "add_extra_deck" && _trait.card_id >= 0) {
        _text = "Add to extra deck " + deck_GetCardName(_trait.card_id);
    } else if (_trait.type == "add_hand_tag" || _trait.type == "add_deck_tag" || _trait.type == "add_extra_deck_tag"
        || _trait.type == "add_hand_with_cost") {
        _text = trait_GetDisplayText(_trait);
    }

    _text = trait_AppendRepeatDisplayText(_text, _trait);

    return _text;
}

function SCR_DBD_GetCardAbilityLines(_card) {
    var _traits = trait_GetFromCard(_card);
    var _lines = [];

    for (var t = 0; t < array_length(_traits); t++) {
        if (_traits[t].type == "none" || _traits[t].type == "conditions") continue;
        array_push(_lines, SCR_DBD_FormatTraitLine(_traits[t]));
    }

    if (array_length(_lines) <= 0) array_push(_lines, "None");
    return _lines;
}

function SCR_DBD_GetCardConditionLines(_card) {
    var _lines = [];
    if (_card == undefined) return _lines;
    if (_card.type != "spirit" && _card.type != "special_monster") return _lines;

    var _conds = conditions_GetRequirements(_card);
    if (array_length(_conds) <= 0) {
        array_push(_lines, "None");
        return _lines;
    }

    for (var c = 0; c < array_length(_conds); c++) {
        array_push(_lines, conditions_GetRequirementText(_conds[c]));
    }
    return _lines;
}

function SCR_DBD_ShouldShowPreviewConditions(_card) {
    if (_card == undefined) return false;
    return (_card.type == "spirit" || _card.type == "special_monster");
}

function SCR_DBD_GetCardPreviewSprite(_card) {
    if (_card == undefined) return noone;

    if (variable_struct_exists(_card, "base_attack")) {
        return SCR_Monster_GetSprite(_card);
    }

    switch (_card.type) {
        case "monster":
        case "spirit":
        case "special_monster":
            return SPR_Monsterplaceholder;
        case "weapon":
            return SPR_Weaponplaceholder;
        case "action":
            return SPR_Actionplaceholder;
    }
    return noone;
}

function SCR_DBD_GetSpiritCardRowBounds(_row_index) {
    var _cx = extra_x + (extra_w - extra_card_w) / 2;
    var _cy = extra_y + 10 + _row_index * (extra_card_h + extra_gap);
    return {
        x: _cx,
        y: _cy,
        w: extra_card_w,
        h: extra_card_h
    };
}

function SCR_DBD_FindHoveredSpiritCard() {
    if (mouse_x < extra_x || mouse_x >= extra_x + extra_w
        || mouse_y < extra_y || mouse_y >= extra_y + extra_h) {
        return undefined;
    }

    var _cards = SCR_DBD_GetSpiritCards();
    var _start = extra_current_page * extra_cards_per_page;
    var _end = min(_start + extra_cards_per_page, array_length(_cards));

    for (var i = _start; i < _end; i++) {
        var _row = i - _start;
        var _bounds = SCR_DBD_GetSpiritCardRowBounds(_row);
        if (mouse_x >= _bounds.x && mouse_x < _bounds.x + _bounds.w
            && mouse_y >= _bounds.y && mouse_y < _bounds.y + _bounds.h) {
            return _cards[i];
        }
    }

    return undefined;
}

function SCR_DBD_FindHoveredPreviewCard() {
    var _spirit = SCR_DBD_FindHoveredSpiritCard();
    if (_spirit != undefined) return _spirit;

    var _layout = SCR_DBD_GetDeckListLayout();
    var _entries = SCR_DBD_GetDeckListSummary(selected_deck);
    var _scroll = SCR_DBD_ClampDeckListScroll(_layout, SCR_DBD_GetDeckListScroll(), array_length(_entries));
    SCR_DBD_SetDeckListScroll(_scroll);

    for (var i = 0; i < array_length(_entries); i++) {
        var _bounds = SCR_DBD_GetDeckListRowBounds(_layout, i, _scroll);
        if (!SCR_DBD_IsDeckListRowInViewport(_layout, _bounds)) continue;
        if (SCR_DBD_IsDeckListRowHovered(_bounds)) {
            return SCR_DBD_ResolveCardDefinition(_entries[i].id);
        }
    }

    var _slot = SCR_DBS_FindCollectionCardUnderMouse();
    if (_slot != noone) {
        var _data = undefined;
        with (_slot) { _data = card_data; }
        return _data;
    }

    return undefined;
}

function SCR_DBD_ShouldShowPreviewTags(_card) {
    if (_card == undefined) return true;
    // Enemy field units only — player cards (including monsters) show tags
    if (variable_struct_exists(_card, "base_attack")) return false;
    return true;
}

function SCR_DBD_DrawCardPreviewPanel(_panel, _card, _summary_lines, _ability_lines, _title_color = c_white, _condition_lines = undefined) {
    var _pad = 12;
    var _line_h = 16;

    draw_set_alpha(0.72);
    draw_set_color(make_color_rgb(28, 28, 32));
    draw_rectangle(_panel.x, _panel.y, _panel.x + _panel.w, _panel.y + _panel.h, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(150, 150, 160));
    draw_rectangle(_panel.x, _panel.y, _panel.x + _panel.w, _panel.y + _panel.h, true);

    var _cx = _panel.x + _pad;
    var _cy = _panel.y + _pad;
    var _inner_w = _panel.w - (_pad * 2);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_title_color);
    draw_text_ext(_cx, _cy, _card.name, _line_h + 2, _inner_w);
    _cy += string_height_ext(_card.name, _line_h + 2, _inner_w) + 8;

    if (SCR_DBD_ShouldShowPreviewTags(_card)) {
        var _tags_line = "Tags: " + SCR_DBD_FormatCardTags(_card);
        draw_set_color(c_aqua);
        draw_text_ext(_cx, _cy, _tags_line, _line_h, _inner_w);
        _cy += string_height_ext(_tags_line, _line_h, _inner_w) + 10;
    }

    var _img_w = min(108, floor(_inner_w * 0.38));
    var _img_h = 136;
    var _summary_x = _cx + _img_w + 10;
    var _summary_w = max(80, _inner_w - _img_w - 10);

    draw_set_color(make_color_rgb(18, 18, 22));
    draw_rectangle(_cx, _cy, _cx + _img_w, _cy + _img_h, false);
    draw_set_color(make_color_rgb(90, 90, 95));
    draw_rectangle(_cx, _cy, _cx + _img_w, _cy + _img_h, true);

    var _spr = SCR_DBD_GetCardPreviewSprite(_card);
    if (_spr != noone) {
        var _spr_w = sprite_get_width(_spr);
        var _spr_h = sprite_get_height(_spr);
        var _area_w = _img_w - 10;
        var _area_h = _img_h - 10;
        var _scale = min(_area_w / _spr_w, _area_h / _spr_h);
        draw_sprite_ext(_spr, 0, _cx + (_img_w * 0.5), _cy + (_img_h * 0.5), _scale, _scale, 0, c_white, 1);
    }

    draw_set_color(c_yellow);
    draw_text(_summary_x, _cy, "Summary");
    var _sum_y = _cy + _line_h + 2;
    draw_set_color(c_ltgray);
    for (var s = 0; s < array_length(_summary_lines); s++) {
        draw_text_ext(_summary_x, _sum_y, _summary_lines[s], _line_h, _summary_w);
        _sum_y += string_height_ext(_summary_lines[s], _line_h, _summary_w) + 3;
    }

    _cy = max(_cy + _img_h, _sum_y) + 14;

    draw_set_color(make_color_rgb(80, 80, 90));
    draw_line(_cx, _cy, _cx + _inner_w, _cy);
    _cy += 10;

    draw_set_color(c_yellow);
    draw_text(_cx, _cy, "Ability");
    _cy += _line_h + 4;

    draw_set_color(c_white);
    for (var t = 0; t < array_length(_ability_lines); t++) {
        var _ability_line = "• " + _ability_lines[t];
        draw_text_ext(_cx, _cy, _ability_line, _line_h, _inner_w);
        _cy += string_height_ext(_ability_line, _line_h, _inner_w) + 4;
    }

    if (_condition_lines != undefined) {
        _cy += 6;
        draw_set_color(make_color_rgb(80, 80, 90));
        draw_line(_cx, _cy, _cx + _inner_w, _cy);
        _cy += 10;

        draw_set_color(c_yellow);
        draw_text(_cx, _cy, "Conditions");
        _cy += _line_h + 4;

        draw_set_color(c_white);
        for (var c = 0; c < array_length(_condition_lines); c++) {
            var _cond_line = "• " + _condition_lines[c];
            draw_text_ext(_cx, _cy, _cond_line, _line_h, _inner_w);
            _cy += string_height_ext(_cond_line, _line_h, _inner_w) + 4;
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function SCR_DBD_DrawHoverPreview() {
    var _card = SCR_DBD_FindHoveredPreviewCard();
    if (_card == undefined) return;

    SCR_DBD_DrawCardPreviewPanel(
        SCR_DBD_GetPreviewPanelLayout(),
        _card,
        SCR_DBD_GetCardSummaryLines(_card),
        SCR_DBD_GetCardAbilityLines(_card),
        c_white,
        SCR_DBD_ShouldShowPreviewConditions(_card) ? SCR_DBD_GetCardConditionLines(_card) : undefined
    );
}
