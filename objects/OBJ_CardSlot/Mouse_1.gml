// check if mouse is over this card
if (mouse_x > x && mouse_x < x + card_w
&&  mouse_y > y && mouse_y < y + card_h) {
    if (count > 0) {
        var _builder = instance_find(OBJ_DeckBuilder, 0);
        for (var i = 0; i < array_length(_builder.selected_deck); i++) {
            if (_builder.selected_deck[i] == card_id) {
                array_delete(_builder.selected_deck, i, 1);
                count--;
                break;
            }
        }
    }
}