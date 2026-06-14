function SCR_Hand_Draw() {
    if (hand_Count == 0) return;
    
    var _max_spread = 5;
    var _spacing = SCR_Hand_GetSpacing(hand_Count, _max_spread);
    var _card_w = 73;
    
    // Calculate total width of hand and center it
    var _total_width = (_spacing * (hand_Count - 1)) + _card_w;
    var _center_x = 600 / 2;
    var _start_x = _center_x - (_total_width / 2);
    
    // Find hovered index scanning right to left
    var _hovered_index = -1;
    for (var i = hand_Count - 1; i >= 0; i--) {
        if (SCR_Hand_IsHovered(i, hand_Count, _spacing, _start_x)) {
            _hovered_index = i;
            break;
        }
    }
    
    // Draw non-hovered cards
    for (var i = 0; i < hand_Count; i++) {
        if (i != _hovered_index) {
            SCR_Hand_DrawCard(i, _spacing, false, 0, _start_x);
        }
    }
    
    // Draw hovered card on top
    if (_hovered_index != -1) {
        SCR_Hand_DrawCard(_hovered_index, _spacing, true, 0, _start_x);
    }
    
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}