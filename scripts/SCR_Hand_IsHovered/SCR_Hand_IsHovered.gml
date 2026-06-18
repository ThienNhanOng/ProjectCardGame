function SCR_Hand_IsHovered(_index, _count, _spacing, _start_x) {
    var _hovered = SCR_Hand_GetBaseHoveredIndex(mouse_x, mouse_y, _count, _spacing, hand_Y);
    return _index == _hovered;
}
