

if (just_created) {
    just_created = false;
    exit;
}

var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);

if (mouse_check_button_pressed(mb_left) && _deckbuilder != noone && !_deckbuilder.click_processed) {
    if (mouse_x > x && mouse_x < x + card_w && 
        mouse_y > y && mouse_y < y + card_h) {
        _deckbuilder.click_processed = true;
        SCR_CardSlot_AddToDeck();
    }
}