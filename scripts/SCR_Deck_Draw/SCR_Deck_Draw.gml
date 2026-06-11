// ===== DECK DRAW SCRIPT (with debug option) =====
function SCR_Deck_Draw(_debug = false) {
    // Draw deck pile with actual card images
    for (var i = 0; i < deck_Count; i++) {
        var _card_id = deck[i];
        var _card_data = deck_GetCardData(_card_id);
        
        if (_card_data != undefined) {
            var _spr = SPR_Monsterplaceholder;
            switch (_card_data.type) {
                case "monster":
                case "special_monster":
                    _spr = SPR_Monsterplaceholder;
                    break;
                case "weapon":
                    _spr = SPR_Weaponplaceholder;
                    break;
                case "action":
                    _spr = SPR_Actionplaceholder;
                    break;
            }
            draw_sprite(_spr, 0, deck_X + (i * 0.4), deck_Y - (i * 0.4));
            
            // Debug: Draw card name
            if (_debug) {
                draw_set_color(c_black);
                draw_set_halign(fa_center);
                draw_text(deck_X + (deck_Width / 2), deck_Y + 20 + (i * 0.4), _card_data.name);
            }
        }
    }
    
    // Draw card count
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(deck_X + (deck_Width / 2), deck_Y + deck_Height + 10, "Cards: " + string(deck_Count));
    draw_set_halign(fa_left);
}