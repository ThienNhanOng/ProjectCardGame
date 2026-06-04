// check if mouse is over this card
if (mouse_x > x && mouse_x < x + card_w
&&  mouse_y > y && mouse_y < y + card_h) {
    var _builder = instance_find(OBJ_DeckBuilder, 0);
    if (array_length(_builder.selected_deck) < 40) {
        array_push(_builder.selected_deck, card_id);
        count++;
    } else {
        show_debug_message("Deck full!");
    }
}