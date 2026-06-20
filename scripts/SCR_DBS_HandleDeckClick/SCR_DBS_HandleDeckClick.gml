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
                show_debug_message("Returned " + card_data.name + " to collection");
                SCR_DBD_RebuildGrid();
                break;
            }
        }
    }
}

function SCR_DBS_HandleDeckClick() {
    if (!mouse_check_button_pressed(mb_left)) return;

    var _layout = SCR_DBD_GetDeckListLayout();
    var _entries = SCR_DBD_GetDeckListSummary(selected_deck);
    var _scroll = SCR_DBD_GetDeckListScroll();

    for (var i = 0; i < array_length(_entries); i++) {
        var _bounds = SCR_DBD_GetDeckListRowBounds(_layout, i, _scroll);
        if (!SCR_DBD_IsDeckListRowInViewport(_layout, _bounds)) continue;

        if (mouse_x >= _bounds.x && mouse_x < _bounds.x + _bounds.w
            && mouse_y >= _bounds.y && mouse_y < _bounds.y + _bounds.h) {

            var _removed_id = _entries[i].id;

            for (var d = 0; d < array_length(selected_deck); d++) {
                if (selected_deck[d].id == _removed_id) {
                    show_debug_message("Returned " + selected_deck[d].name + " to collection");
                    array_delete(selected_deck, d, 1);
                    break;
                }
            }

            SCR_DBC_LoadPage();
            break;
        }
    }
}
