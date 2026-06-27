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
