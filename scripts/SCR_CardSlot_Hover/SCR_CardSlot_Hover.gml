// Add this to SCR_CardSlot_Step() or create a new function
function SCR_CardSlot_UpdateHover() {
    // Check if mouse is over this card slot
    var _mx = mouse_x;
    var _my = mouse_y;
    
    if (_mx >= x && _mx <= x + card_w &&
        _my >= y && _my <= y + card_h) {
        is_hovered = true;
    } else {
        is_hovered = false;
    }
}