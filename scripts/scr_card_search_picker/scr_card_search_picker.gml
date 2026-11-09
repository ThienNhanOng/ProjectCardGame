/// @desc Tag search picker — add_hand_tag / add_deck_tag / add_extra_deck_tag / add_hand_with_cost

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

        var _is_spirit = card_IsSpiritType(_def);
        if (_destination == "hand" || _destination == "deck") {
            if (_is_spirit) continue;
        } else if (_destination == "extra_deck") {
            if (!_is_spirit) continue;
        }

        array_push(_ids, _deck_ids[i]);
    }
    return _ids;
}

function card_DB_FindIdsByTags(_tags, _destination = "") {
    var _ids = [];
    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) return _ids;
    if (!variable_struct_exists(card_DB, "cards") || !is_array(card_DB.cards)) return _ids;

    for (var i = 0; i < array_length(card_DB.cards); i++) {
        var _def = card_DB.cards[i];
        if (!card_HasAnyTag(_def, _tags)) continue;

        var _is_spirit = card_IsSpiritType(_def);
        if (_destination == "hand" || _destination == "deck") {
            if (_is_spirit) continue;
        } else if (_destination == "extra_deck") {
            if (!_is_spirit) continue;
        }

        array_push(_ids, _def.id);
    }
    return _ids;
}

function card_DB_FindAllIdsForDestination(_destination = "hand") {
    var _ids = [];
    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) return _ids;
    if (!variable_struct_exists(card_DB, "cards") || !is_array(card_DB.cards)) return _ids;

    for (var i = 0; i < array_length(card_DB.cards); i++) {
        var _def = card_DB.cards[i];
        var _is_spirit = card_IsSpiritType(_def);
        if (_destination == "hand" || _destination == "deck") {
            if (_is_spirit) continue;
        } else if (_destination == "extra_deck") {
            if (!_is_spirit) continue;
        }
        array_push(_ids, _def.id);
    }
    return _ids;
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
    if (card_IsSpiritType(_card_data) && (_destination == "hand" || _destination == "deck")) {
        _destination = "extra_deck";
    }

    var _src = effect_Source(SIDE_PLAYER);
    var _hand = instance_find(OBJ_Hand, 0);
    var _added_any = false;

    for (var i = 0; i < _amount; i++) {
        if (!card_AddCard(_src, _destination, _card_id)) continue;
        _added_any = true;

        // add_hand_with_cost: the new hand card costs extra
        if (_destination == "hand" && _apply_cost > 0 && _hand != noone) {
            with (_hand) {
                if (hand_Count > 0) {
                    card_AppendCostEntry(hand[hand_Count - 1], { amount: _apply_cost });
                }
            }
        }
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
