function SCR_CardSlot_DrawText() {
    var _pad = 4;
    var _name = SCR_Hand_TruncateName(card_data.name, card_w - _pad * 2);

    draw_set_color(c_blue);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(x + _pad, y + 3, _name);
    
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