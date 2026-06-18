function SCR_Hand_Draw() {
    if (hand_Count == 0) return;

    var _spacing = SCR_Hand_GetSpacing(hand_Count, 5);
    var _start_x = SCR_Hand_GetStartX(hand_Count, _spacing);
    var _hovered_index = SCR_Hand_GetBaseHoveredIndex(mouse_x, mouse_y, hand_Count, _spacing, hand_Y);

    for (var i = 0; i < hand_Count; i++) {
        if (i != _hovered_index) {
            SCR_Hand_DrawCard(i, hand_Count, _spacing, false, _start_x);
        }
    }

    if (_hovered_index != -1) {
        SCR_Hand_DrawCard(_hovered_index, hand_Count, _spacing, true, _start_x);
    }

    draw_set_halign(fa_left);
    draw_set_color(c_white);
}
