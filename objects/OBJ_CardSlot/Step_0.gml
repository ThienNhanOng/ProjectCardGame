var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);

if (mouse_check_button_pressed(mb_left) && _deckbuilder != noone && !_deckbuilder.click_processed) {
    
    var _mx = mouse_x;
    var _my = mouse_y;
    var _best_slot = noone;
    var _best_x = -999999;
    
    // EXPAND hitbox to cover gaps between cards
    var _hitbox_expand = 15;  // Increased from 5 to 15
    
    with (OBJ_CardSlot) {
        // Use expanded hitbox
        var _hit_x = x - _hitbox_expand;
        var _hit_y = y - 10;  // Expand vertical slightly too
        var _hit_w = card_w + (_hitbox_expand * 2);
        var _hit_h = card_h + 20;  // Add 20 pixels vertically
        
        if (_mx >= _hit_x && _mx <= _hit_x + _hit_w &&
            _my >= _hit_y && _my <= _hit_y + _hit_h) {
            // Rightmost card gets priority
            if (x > _best_x) {
                _best_x = x;
                _best_slot = id;
            }
        }
    }
    
    if (_best_slot != noone) {
        with (_best_slot) {
            _deckbuilder.click_processed = true;
            SCR_CardSlot_AddToDeck();
        }
    }
}