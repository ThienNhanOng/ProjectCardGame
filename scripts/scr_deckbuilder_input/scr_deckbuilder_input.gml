/// @desc OBJ_DeckBuilder Step — clicks, scrolling, READY button

function SCR_DBS_ApplyCollectionFilters() {
    current_page = 0;
    SCR_DBC_LoadPage();
}

function SCR_DBS_HandleCollectionSearchInput() {
    if (!search_focused) return;

    if (keyboard_check_pressed(vk_backspace)) {
        if (string_length(search_text) > 0) {
            search_text = string_copy(search_text, 1, string_length(search_text) - 1);
            SCR_DBS_ApplyCollectionFilters();
        }
        return;
    }

    if (keyboard_check_pressed(vk_escape)) {
        search_focused = false;
        return;
    }

    if (string_length(keyboard_string) > 0) {
        search_text += keyboard_string;
        keyboard_string = "";
        SCR_DBS_ApplyCollectionFilters();
    }
}

function SCR_DBS_HandleCollectionToolbar() {
    SCR_DBS_HandleCollectionSearchInput();

    if (!mouse_check_button_pressed(mb_left)) return;

    var _layout = SCR_DBD_GetCollectionToolbarLayout();
    var _filter_changed = false;

    if (SCR_DBD_IsToolbarRectHovered(_layout.monster)) {
        filter_type = (filter_type == "monster") ? "" : "monster";
        search_focused = false;
        _filter_changed = true;
    } else if (SCR_DBD_IsToolbarRectHovered(_layout.weapon)) {
        filter_type = (filter_type == "weapon") ? "" : "weapon";
        search_focused = false;
        _filter_changed = true;
    } else if (SCR_DBD_IsToolbarRectHovered(_layout.action)) {
        filter_type = (filter_type == "action") ? "" : "action";
        search_focused = false;
        _filter_changed = true;
    } else if (SCR_DBD_IsToolbarRectHovered(_layout.search)) {
        search_focused = true;
    } else {
        search_focused = false;
    }

    if (_filter_changed) {
        SCR_DBS_ApplyCollectionFilters();
    }
}

function SCR_DBS_PointInCollectionCard(_mx, _my, _x, _y, _w, _h) {
    return (_mx >= _x && _mx < _x + _w && _my >= _y && _my < _y + _h);
}

function SCR_DBS_FindCollectionCardUnderMouse() {
    var _mx = mouse_x;
    var _my = mouse_y;
    var _best_slot = noone;
    var _best_x = -999999;

    with (OBJ_CardSlot) {
        if (SCR_CardSlot_CheckVisibility()
            && SCR_DBS_PointInCollectionCard(_mx, _my, x, y, card_w, card_h)
            && x > _best_x) {
            _best_x = x;
            _best_slot = id;
        }
    }

    return _best_slot;
}

function SCR_DBS_HandleCollectionClick() {
    if (!mouse_check_button_pressed(mb_left)) return;
    if (click_processed) return;

    var _best_slot = SCR_DBS_FindCollectionCardUnderMouse();
    if (_best_slot != noone) {
        with (_best_slot) {
            SCR_CardSlot_AddToDeck();
        }
    }
}

function SCR_DBS_HandleCollectionRightClick() {
    if (!mouse_check_button_pressed(mb_right)) return;

    var _best_slot = SCR_DBS_FindCollectionCardUnderMouse();
    if (_best_slot == noone) return;

    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (_builder == noone) return;

    with (_best_slot) {
        for (var i = 0; i < array_length(_builder.selected_deck); i++) {
            if (_builder.selected_deck[i].id == card_id) {
                array_delete(_builder.selected_deck, i, 1);
                player_deck_PersistSelectedDeck(_builder);
                SCR_DBD_RebuildGrid();
                break;
            }
        }
    }
}

function SCR_DBS_HandleDeckClick() {
    if (!mouse_check_button_pressed(mb_left)) return;

    var _layout = SCR_DBD_GetDeckListLayout();
    var _rows = SCR_DBD_BuildDeckListRows(selected_deck);
    var _scroll = SCR_DBD_GetDeckListScroll();

    for (var i = 0; i < array_length(_rows); i++) {
        if (_rows[i].kind != "card") continue;

        var _bounds = SCR_DBD_GetDeckListRowBounds(_layout, _rows, i, _scroll);
        if (!SCR_DBD_IsDeckListRowInViewport(_layout, _bounds)) continue;

        if (mouse_x >= _bounds.x && mouse_x < _bounds.x + _bounds.w
            && mouse_y >= _bounds.y && mouse_y < _bounds.y + _bounds.h) {

            var _removed_id = _rows[i].id;

            for (var d = 0; d < array_length(selected_deck); d++) {
                if (selected_deck[d].id == _removed_id) {
                    array_delete(selected_deck, d, 1);
                    player_deck_PersistSelectedDeck();
                    break;
                }
            }

            SCR_DBC_LoadPage();
            break;
        }
    }
}

function SCR_DBS_HandleDeckListScrolling() {
    if (search_focused) return false;

    var _layout = SCR_DBD_GetDeckListLayout();
    if (!SCR_DBD_IsMouseOverDeckList(_layout)) return false;

    var _rows = SCR_DBD_BuildDeckListRows(selected_deck);
    var _scroll = SCR_DBD_GetDeckListScroll();
    var _step = SCR_DBD_GetDeckListRowStep(_layout);
    var _changed = false;

    if (mouse_wheel_up()) {
        _scroll -= _step;
        _changed = true;
    }
    if (mouse_wheel_down()) {
        _scroll += _step;
        _changed = true;
    }

    if (_changed) {
        SCR_DBD_SetDeckListScroll(SCR_DBD_ClampDeckListScroll(_layout, _scroll, _rows));
    }

    return true;
}

function SCR_DBS_HandleScrolling() {
    if (search_focused) return;
    if (SCR_DBS_HandleDeckListScrolling()) return;

    var _new_page = current_page;
    var _total_pages = SCR_DBD_GetCollectionPageCount(cards_per_page);

    if (mouse_wheel_up()) {
        _new_page--;
    }
    if (mouse_wheel_down()) {
        _new_page++;
    }

    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
        _new_page++;
    }
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
        _new_page--;
    }

    _new_page = clamp(_new_page, 0, _total_pages - 1);

    if (_new_page != current_page) {
        current_page = _new_page;
        SCR_DBC_LoadPage();
    }
}

/// READY button: save the deck and return to the map that opened the collection
function SCR_DBS_HandleReadyButton() {
    if (!mouse_check_button_pressed(mb_left)) return;

    if (mouse_x <= room_width - 150 || mouse_x >= room_width - 20
        || mouse_y <= room_height - 100 || mouse_y >= room_height - 60) {
        return;
    }

    if (array_length(selected_deck) < 8) return;

    var _main_ids = player_deck_SaveSelectedDeckIds();

    var _extra_ids = [];
    for (var s = 0; s < array_length(global.player_collection); s++) {
        var _spirit = global.player_collection[s];
        if (!card_IsSpiritType(_spirit)) continue;

        var _owned = variable_struct_exists(_spirit, "owned") ? _spirit.owned : 0;
        for (var c = 0; c < _owned; c++) {
            array_push(_extra_ids, _spirit.id);
        }
    }

    battle_SaveDeckSources(_main_ids, _extra_ids);
    room_goto(worldmap_GetCollectionReturnRoom());
}
