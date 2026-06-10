function SCR_CardSlot_DrawText() {
    // Name - Blue color
    draw_set_color(c_blue);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(x + card_w / 2, y + 3, card_data.name);
    
    // Type
    var _type_text = card_data.type;
    if (_type_text == "special_monster") {
        _type_text = "spirit";
    }
    
    switch (card_data.type) {
        case "monster":         draw_set_color(c_gray);   break;
        case "special_monster": draw_set_color(c_purple); break;
        case "weapon":          draw_set_color(c_red);    break;
        case "action":          draw_set_color(c_blue);   break;
    }
    draw_set_halign(fa_center);
    draw_text(x + card_w / 2, y + 16, _type_text);
}