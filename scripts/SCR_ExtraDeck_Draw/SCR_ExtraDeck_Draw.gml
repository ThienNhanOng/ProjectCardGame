/// @description Draw the extra deck container, label, page counter, and visible cards
function SCR_ExtraDeck_Draw() {
    draw_set_color(c_black);
    draw_set_alpha(0.3);
    draw_rectangle(extra_x, extra_y, extra_x + extra_w, extra_y + extra_h, false);
    draw_set_alpha(1);
    
    draw_set_color(c_white);
    draw_rectangle(extra_x, extra_y, extra_x + extra_w, extra_y + extra_h, true);
    
    // Label
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(extra_x, extra_y - 40, "Spirit Owned");
    
    // Get ONLY spirit cards
    extra_cards = SCR_DBD_GetSpiritCards();
    extra_total_pages = ceil(array_length(extra_cards) / extra_cards_per_page);
    if (extra_total_pages < 1) extra_total_pages = 1;
    
    // Page counter - right aligned with the box edge
    draw_set_halign(fa_right);
    draw_text(extra_x + extra_w, extra_y - 20, "Page " + string(extra_current_page + 1) + "/" + string(extra_total_pages));
    draw_set_halign(fa_left);
    
    var _start = extra_current_page * extra_cards_per_page;
    var _end   = min(_start + extra_cards_per_page, array_length(extra_cards));
    
    for (var i = _start; i < _end; i++) {
        var _card_data = extra_cards[i];
        var _row = i - _start;
        var _bounds = SCR_DBD_GetSpiritCardRowBounds(_row);

        SCR_ExtraDeck_DrawCard(_bounds.x, _bounds.y, _bounds.w, _bounds.h, _card_data);
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}