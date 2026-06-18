function SCR_DBS_HandleScrolling() {
    if (search_focused) return;

    var _new_page = current_page;
    var _total_pages = SCR_DBD_GetCollectionPageCount(cards_per_page);
    
    // Mouse wheel
    if (mouse_wheel_up()) {
        _new_page--;
    }
    if (mouse_wheel_down()) {
        _new_page++;
    }
    
    // Keyboard
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
        _new_page++;
    }
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
        _new_page--;
    }
    
    // Clamp and apply
    _new_page = clamp(_new_page, 0, _total_pages - 1);
    
    if (_new_page != current_page) {
        current_page = _new_page;
        SCR_DBC_LoadPage();
    }
}