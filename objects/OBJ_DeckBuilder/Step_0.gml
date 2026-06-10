// Mouse wheel scrolling (page up/down)
if (mouse_wheel_up()) {
    if (current_page > 0) {
        current_page--;
        LoadCardPage();
    }
}
if (mouse_wheel_down()) {
    var _total_pages = ceil(array_length(card_DB.cards) / cards_per_page);
    if (current_page < _total_pages - 1) {
        current_page++;
        LoadCardPage();
    }
}

// Keyboard scrolling
if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
    var _total_pages = ceil(array_length(card_DB.cards) / cards_per_page);
    if (current_page < _total_pages - 1) {
        current_page++;
        LoadCardPage();
    }
}
if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
    if (current_page > 0) {
        current_page--;
        LoadCardPage();
    }
}