function SCR_DragDrop_Init() {
    drag_card       = undefined;
    drag_hand_index = -1;
    drag_x          = 0;
    drag_y          = 0;
    is_dragging     = false;
}

function SCR_DragDrop_Step() {
    var _mx = mouse_x;
    var _my = mouse_y;
    
    if (mouse_check_button_pressed(mb_left) && !is_dragging) {
        var _hand = instance_find(OBJ_Hand, 0);
        if (_hand == noone) return;
        
        var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
        var _card_w  = 73;
        var _card_h  = 101;
        var _total_width = (_spacing * (_hand.hand_Count - 1)) + _card_w;
        var _start_x = (600 / 2) - (_total_width / 2);
        
        for (var i = _hand.hand_Count - 1; i >= 0; i--) {
            var _cx = _start_x + (i * _spacing);
            var _cy = _hand.hand_Y;
            var _right = (i < _hand.hand_Count - 1) ? _start_x + ((i + 1) * _spacing) : _cx + _card_w;
            
            if (_mx >= _cx && _mx < _right &&
                _my >= _cy && _my <= _cy + _card_h) {
                drag_card       = _hand.hand[i];
                drag_hand_index = i;
                drag_x          = _mx;
                drag_y          = _my;
                is_dragging     = true;
                show_debug_message("Dragging: " + drag_card.name);
                break;
            }
        }
    }
    
    if (is_dragging) {
        drag_x = _mx;
        drag_y = _my;
        SCR_Board_UpdateHover(_mx, _my, drag_card);
        
        if (mouse_check_button_released(mb_left)) {
            var _slot = SCR_Board_GetSlotAt(_mx, _my);
            if (_slot != undefined && !_slot.occupied && !_slot.locked) {
                if (SCR_Board_PlaceCard(_slot, drag_card)) {
                    var _hand = instance_find(OBJ_Hand, 0);
                    if (_hand != noone) {
                        var _index = drag_hand_index;
                        with (_hand) {
                            hand_RemoveCard(_index);
                        }
                    }
                }
            }
            SCR_DragDrop_Cancel();
        }
    }
}

function SCR_DragDrop_Draw() {
    if (!is_dragging || drag_card == undefined) return;
    
    var _spr = SCR_Hand_GetSprite(drag_card);
    draw_sprite_ext(_spr, 0, drag_x - 36, drag_y - 50, 1.1, 1.1, 0, c_white, 0.85);
    draw_set_color(c_black);
    draw_set_halign(fa_center);
    draw_text(drag_x, drag_y - 40, drag_card.name);
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

function SCR_DragDrop_Cancel() {
    drag_card       = undefined;
    drag_hand_index = -1;
    is_dragging     = false;
    SCR_Board_ClearHover();
}