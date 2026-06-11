// ===== HAND DRAW SCRIPT =====
// Call this in OBJ_Hand Draw Event: SCR_Hand_Draw();

function SCR_Hand_Draw() {
    for (var i = 0; i < hand_Count; i++) {
        var _card = hand[i];
        if (_card != undefined) {
            var _x = hand_X + (i * hand_Spacing);
            var _y = hand_Y;
            
            // Get sprite based on card type
            var _spr = SPR_Monsterplaceholder;
            switch (_card.type) {
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
            
            // Draw card background
            draw_sprite(_spr, 0, _x, _y);
            
            // Draw card name
            draw_set_color(c_black);
            draw_set_halign(fa_center);
            draw_text(_x + 36, _y + 10, _card.name);
            
            // Draw card level/health if exists
            if (variable_struct_exists(_card, "level")) {
                draw_set_color(c_yellow);
                draw_text(_x + 36, _y + 25, "Lv " + string(_card.level));
            }
            
            // Draw card type
            draw_set_color(c_white);
            var _type = (_card.type == "special_monster") ? "spirit" : _card.type;
            draw_text(_x + 36, _y + 40, _type);
        }
    }
    
    // Reset draw settings
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}