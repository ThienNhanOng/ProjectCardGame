function SCR_Hand_GetSpacing(_count, _max_spread) {
    var _hand_start_x = 20;
    var _hand_end_x = 555;
    var _card_w = 73;
    var _normal_spacing = 85;
    
    if (_count <= 1) return _normal_spacing;
    
    // Max width we can use
    var _available_width = _hand_end_x - _hand_start_x - _card_w;
    
    // Normal spacing — check if it fits
    if (_count * _normal_spacing + _card_w <= _hand_end_x - _hand_start_x) {
        return _normal_spacing;
    }
    
    // Compress to fit within bounds
    return _available_width / (_count - 1);
}