// ===== DECK DEBUG DRAW - SHOW CARDS IN A ROW =====
// Call this in OBJ_Deck Draw Event: SCR_Deck_DrawDebugRow();

function SCR_Deck_DrawDebugRow() {
    var _start_x = 100;
    var _start_y = 500;
    var _card_width = 73;
    var _card_height = 101;
    var _spacing = 10;
    
    for (var i = 0; i < deck_Count; i++) {
        var _card_id = deck[i];
        var _card_data = deck_GetCardData(_card_id);
        
        if (_card_data != undefined) {
            var _x = _start_x + i * (_card_width + _spacing);
            var _y = _start_y;
            
            // Get sprite based on card type
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
            
            // Draw card
            draw_sprite(_spr, 0, _x, _y);
            
            // Draw card name
            draw_set_color(c_black);
            draw_set_halign(fa_center);
            draw_text(_x + (_card_width / 2), _y + _card_height + 10, _card_data.name);
            
            // Draw card ID
            draw_set_color(c_red);
            draw_text(_x + (_card_width / 2), _y + _card_height + 25, "ID: " + string(_card_id));
        }
    }
    
    // Reset draw settings
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}