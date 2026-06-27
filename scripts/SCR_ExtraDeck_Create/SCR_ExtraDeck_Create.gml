/// @description Initialize the extra deck strip - filters spirit cards from collection
function SCR_ExtraDeck_Init() {
    extra_x       = container_x + container_w + 5;
    extra_y       = container_y;
    extra_card_w  = card_w;
    extra_card_h  = card_h;
    extra_w       = card_w + 20;
    extra_h       = container_h;
    extra_gap     = grid_padding_y;
    
    extra_visible_count = floor(extra_h / (extra_card_h + extra_gap));
    
    extra_cards = [];
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (_card.type == "spirit" && _card.owned > 0) {
            array_push(extra_cards, _card);
        }
    }
    
    extra_current_page = 0;
    extra_cards_per_page = extra_visible_count;
    extra_total_pages = ceil(array_length(extra_cards) / extra_cards_per_page);
    if (extra_total_pages < 1) extra_total_pages = 1;
}
