// destroy any leftover card slots first
with (OBJ_CardSlot) {
    instance_destroy();
}

// grid settings
grid_cols      = 5;
card_w         = 100;
card_h         = 140;
grid_padding_x = 40;
grid_padding_y = 80;
grid_start_x   = 80;
grid_start_y   = 80;

// selected deck list
selected_deck = [];

// spawn card slots
var _cards = card_DB.cards;
for (var i = 0; i < array_length(_cards); i++) {
    var _col = i mod grid_cols;
    var _row = i div grid_cols;
    var _x   = grid_start_x + _col * (card_w + grid_padding_x);
    var _y   = grid_start_y + _row * (card_h + grid_padding_y);
    var _slot       = instance_create_layer(_x, _y, "Instances", OBJ_CardSlot);
    _slot.card_id   = _cards[i].id;
    _slot.card_data = _cards[i];
    _slot.count     = 0;
    _slot.card_w    = card_w;
    _slot.card_h    = card_h;
}