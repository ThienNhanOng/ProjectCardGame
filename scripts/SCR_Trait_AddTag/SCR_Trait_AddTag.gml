/// @desc Search card_DB by tag and add chosen card to hand / deck / extra deck

function trait_ParseIndeckTags(_raw) {
    var _tags = [];

    if (variable_struct_exists(_raw, "indeckTags") && is_array(_raw.indeckTags)) {
        for (var i = 0; i < array_length(_raw.indeckTags); i++) {
            array_push(_tags, string(_raw.indeckTags[i]));
        }
    } else if (variable_struct_exists(_raw, "indeckTag")) {
        if (is_array(_raw.indeckTag)) {
            for (var j = 0; j < array_length(_raw.indeckTag); j++) {
                array_push(_tags, string(_raw.indeckTag[j]));
            }
        } else {
            array_push(_tags, string(_raw.indeckTag));
        }
    }

    return _tags;
}

function trait_TraitUsesIndeckTagSearch(_trait) {
    return (_trait != undefined
        && variable_struct_exists(_trait, "indeck_tags")
        && is_array(_trait.indeck_tags)
        && array_length(_trait.indeck_tags) > 0);
}

function trait_GetTraitSearchTags(_trait) {
    if (trait_TraitUsesIndeckTagSearch(_trait)) return _trait.indeck_tags;
    if (variable_struct_exists(_trait, "tags") && is_array(_trait.tags)) return _trait.tags;
    return [];
}

function deck_GetUniqueBattleDeckCardIds(_destination = "") {
    var _ids = [];
    var _seen = {};

    if (_destination == "extra_deck") {
        for (var e = 0; e < extra_deck_Count; e++) {
            var _extra_id = extraDeck_GetCardId(extra_deck[e]);
            if (_extra_id <= 0) continue;
            var _extra_key = string(_extra_id);
            if (variable_struct_exists(_seen, _extra_key)) continue;
            _seen[$ _extra_key] = true;
            array_push(_ids, _extra_id);
        }
        return _ids;
    }

    for (var i = 0; i < deck_Count; i++) {
        var _card_id = deck[i];
        if (_card_id <= 0) continue;
        var _key = string(_card_id);
        if (variable_struct_exists(_seen, _key)) continue;
        _seen[$ _key] = true;
        array_push(_ids, _card_id);
    }
    return _ids;
}

function deck_FindIdsByIndeckTags(_tags, _destination = "") {
    var _ids = [];
    var _deck_ids = deck_GetUniqueBattleDeckCardIds(_destination);

    for (var i = 0; i < array_length(_deck_ids); i++) {
        var _def = deck_GetCardData(_deck_ids[i]);
        if (_def == undefined) continue;
        if (!card_HasAnyTag(_def, _tags)) continue;

        var _is_spirit = card_IsExtraDeckType(_def);
        if (_destination == "hand" || _destination == "deck") {
            if (_is_spirit) continue;
        } else if (_destination == "extra_deck") {
            if (!_is_spirit) continue;
        }

        array_push(_ids, _deck_ids[i]);
    }
    return _ids;
}

function trait_ParseTags(_raw) {
    var _tags = [];

    if (variable_struct_exists(_raw, "tags") && is_array(_raw.tags)) {
        for (var i = 0; i < array_length(_raw.tags); i++) {
            array_push(_tags, string(_raw.tags[i]));
        }
    } else if (variable_struct_exists(_raw, "tag")) {
        array_push(_tags, string(_raw.tag));
    }

    return _tags;
}

function card_HasAnyTag(_card, _tags) {
    if (_card == undefined || array_length(_tags) <= 0) return false;
    if (!variable_struct_exists(_card, "tag") || !is_array(_card.tag)) return false;

    for (var t = 0; t < array_length(_tags); t++) {
        var _want = string_lower(string_trim(_tags[t]));
        for (var c = 0; c < array_length(_card.tag); c++) {
            if (string_lower(string(_card.tag[c])) == _want) return true;
        }
    }
    return false;
}

function card_IsExtraDeckType(_card) {
    return (_card != undefined && (_card.type == "spirit" || _card.type == "special_monster"));
}

function card_DB_FindIdsByTags(_tags, _destination = "") {
    var _ids = [];
    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) return _ids;
    if (!variable_struct_exists(card_DB, "cards") || !is_array(card_DB.cards)) return _ids;

    for (var i = 0; i < array_length(card_DB.cards); i++) {
        var _def = card_DB.cards[i];
        if (!card_HasAnyTag(_def, _tags)) continue;

        var _is_spirit = card_IsExtraDeckType(_def);
        if (_destination == "hand" || _destination == "deck") {
            if (_is_spirit) continue;
        } else if (_destination == "extra_deck") {
            if (!_is_spirit) continue;
        }

        array_push(_ids, _def.id);
    }
    return _ids;
}

function trait_GetTagDestinationLabel(_destination) {
    switch (_destination) {
        case "hand": return "hand";
        case "deck": return "deck";
        case "extra_deck": return "extra deck";
        default: return _destination;
    }
}

function trait_ParseApplyCost(_raw) {
    if (_raw == undefined || !variable_struct_exists(_raw, "cost")) return 0;

    var _entry = card_NormalizeCostEntry(_raw.cost);
    if (_entry != undefined) {
        if (card_CostEntryIsTribute(_entry)) return max(0, _entry.amount);
        return max(0, _entry.amount);
    }

    return 0;
}

function card_DB_FindAllIdsForDestination(_destination = "hand") {
    var _ids = [];
    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) return _ids;
    if (!variable_struct_exists(card_DB, "cards") || !is_array(card_DB.cards)) return _ids;

    for (var i = 0; i < array_length(card_DB.cards); i++) {
        var _def = card_DB.cards[i];
        var _is_spirit = card_IsExtraDeckType(_def);
        if (_destination == "hand" || _destination == "deck") {
            if (_is_spirit) continue;
        } else if (_destination == "extra_deck") {
            if (!_is_spirit) continue;
        }
        array_push(_ids, _def.id);
    }
    return _ids;
}

function trait_GetTagDestinationFromType(_type) {
    switch (_type) {
        case "add_hand_tag":
        case "add_tag":
        case "add_hand_with_cost":
        case "addtohandwithcost": return "hand";
        case "add_deck_tag": return "deck";
        case "add_extra_deck_tag": return "extra_deck";
        default: return "";
    }
}

function deck_TagPicker_Close() {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return;

    var _was_open = false;
    with (_deck) {
        _was_open = tag_picker_open;
        tag_picker_open = false;
        tag_picker_scroll = 0;
        tag_picker_focus = 0;
        tag_picker_card_ids = [];
        tag_picker_destination = "";
        tag_picker_amount = 1;
        tag_picker_title = "";
        tag_picker_footer_hint = "";
        tag_picker_apply_cost = 0;
    }

    if (_was_open) {
        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) trait_ChainFinish();
        }
    }
}

function deck_TagPicker_Begin(_trait) {
    if (_trait == undefined) return false;

    var _destination = trait_GetTagDestinationFromType(_trait.type);
    if (_destination == "") return false;

    var _tags = trait_GetTraitSearchTags(_trait);
    var _use_indeck = trait_TraitUsesIndeckTagSearch(_trait);
    var _any_tag = (_trait.type == "add_hand_with_cost" && array_length(_tags) <= 0);

    if (!_any_tag && array_length(_tags) <= 0) {
return false;
    }

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;

    var _ids = [];
    with (_deck) {
        if (_any_tag) {
            _ids = card_DB_FindAllIdsForDestination(_destination);
        } else {
            _ids = _use_indeck
                ? deck_FindIdsByIndeckTags(_tags, _destination)
                : card_DB_FindIdsByTags(_tags, _destination);
        }
    }
    if (array_length(_ids) <= 0) {
        var _scope = _use_indeck ? "in-deck " : "";
return false;
    }

    var _dest_label = trait_GetTagDestinationLabel(_destination);
    var _scope_label = _use_indeck ? "in deck " : "";
    var _tag_label = _any_tag ? "any tag" : trait_GetTagsDisplayText(_tags);
    var _apply_cost = 0;
    if (variable_struct_exists(_trait, "apply_cost")) {
        _apply_cost = max(0, floor(real(_trait.apply_cost)));
    }

    with (_deck) {
        tag_picker_card_ids = _ids;
        tag_picker_destination = _destination;
        tag_picker_amount = max(1, _trait.amount);
        tag_picker_apply_cost = _apply_cost;
        tag_picker_title = "Choose card (" + _scope_label + _tag_label + ")";
        tag_picker_footer_hint = "Click card to add to " + _dest_label;
        if (_apply_cost > 0) {
            tag_picker_footer_hint += " (cost " + string(_apply_cost) + ")";
        }
        tag_picker_open = true;
        tag_picker_scroll = 0;
        tag_picker_focus = 0;

        if (extra_deck_picker_open) deck_ExtraDeckPicker_Close();
    }

return true;
}

function trait_GetTagsDisplayText(_tags) {
    if (_tags == undefined || array_length(_tags) <= 0) return "any tag";

    var _txt = "";
    for (var i = 0; i < array_length(_tags); i++) {
        if (i > 0) _txt += ", ";
        _txt += _tags[i];
    }
    return _txt;
}

function deck_TagPicker_AddCard(_card_id) {
    if (_card_id <= 0) return false;

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;

    var _amount = 1;
    var _destination = "";
    var _apply_cost = 0;
    with (_deck) {
        _amount = max(1, tag_picker_amount);
        _destination = tag_picker_destination;
        _apply_cost = max(0, tag_picker_apply_cost);
    }

    var _card_data = deck_GetCardData(_card_id);
    if (card_IsExtraDeckType(_card_data) && (_destination == "hand" || _destination == "deck")) {
        _destination = "extra_deck";
    }

    var _added_any = false;

    switch (_destination) {
        case "hand":
            var _hand = instance_find(OBJ_Hand, 0);
            for (var h = 0; h < _amount; h++) {
                if (trait_ExecuteAddHand(trait_CreateAddHandContext(_card_id))) {
                    _added_any = true;
                    if (_apply_cost > 0 && _hand != noone) {
                        with (_hand) {
                            if (hand_Count > 0) {
                                card_AppendCostEntry(hand[hand_Count - 1], { amount: _apply_cost });
                            }
                        }
                    }
                }
            }
            break;

        case "deck":
            with (_deck) {
                for (var d = 0; d < _amount; d++) {
                    if (deck_AddCard(_card_id)) {
                        _added_any = true;
                        var _bm = instance_find(OBJ_BattleManager, 0);
                        if (_bm != noone) {
                            with (_bm) trait_ChainRegisterAddedDeckId(_card_id);
                        }
                    }
                }
            }
            break;

        case "extra_deck":
            with (_deck) {
                for (var e = 0; e < _amount; e++) {
                    if (deck_AddExtraCard(_card_id)) {
                        _added_any = true;
                        var _bm = instance_find(OBJ_BattleManager, 0);
                        if (_bm != noone) {
                            with (_bm) trait_ChainRegisterAddedDeckId(_card_id);
                        }
                    }
                }
            }
            break;
    }

    return _added_any;
}

function deck_TagPicker_SelectIndex(_index) {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;

    var _card_id = -1;
    with (_deck) {
        if (_index >= 0 && _index < array_length(tag_picker_card_ids)) {
            _card_id = tag_picker_card_ids[_index];
        }
    }

    if (_card_id <= 0) return false;

    var _ok = deck_TagPicker_AddCard(_card_id);
    deck_TagPicker_Close();
    return _ok;
}

function deck_TagPicker_Step() {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return;

    var _open = false;
    with (_deck) { _open = tag_picker_open; }
    if (!_open) return;

    if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
        deck_TagPicker_Close();
        return;
    }

    var _scroll = 0;
    var _card_ids = [];
    with (_deck) {
        var _input = deck_ScrollPicker_ApplyScrollInput(tag_picker_card_ids, tag_picker_scroll, tag_picker_focus);
        tag_picker_scroll = _input.scroll;
        tag_picker_focus = _input.focus;
        _scroll = tag_picker_scroll;
        _card_ids = tag_picker_card_ids;
    }

    if (!mouse_check_button_pressed(mb_left)) return;

    var _layout = deck_ScrollPicker_GetLayout();
    if (mouse_x >= _layout.left && mouse_x <= _layout.right &&
        mouse_y >= _layout.top && mouse_y <= _layout.bottom) {
        var _picked = deck_ScrollPicker_PickIndexAt(mouse_x, mouse_y, _card_ids, _scroll);
        if (_picked >= 0) {
            with (_deck) tag_picker_focus = _picked;
            deck_TagPicker_SelectIndex(_picked);
        }
    } else {
        deck_TagPicker_Close();
    }
}

function trait_ExecuteAddHandTag(_trait) {
    return deck_TagPicker_Begin(_trait);
}

function trait_ExecuteAddHandWithCost(_trait) {
    if (_trait == undefined || _trait.type != "add_hand_with_cost") return false;
    if (_trait.apply_cost <= 0) {
return false;
    }
    return deck_TagPicker_Begin(_trait);
}

function trait_ExecuteAddDeckTag(_trait) {
    return deck_TagPicker_Begin(_trait);
}

function trait_ExecuteAddExtraDeckTag(_trait) {
    return deck_TagPicker_Begin(_trait);
}
