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
    var _bm = instance_find(OBJ_BattleManager, 0);
    var _targeting = false;

    if (_bm != noone) {
        with (_bm) {
            _targeting = battle_IsTargeting();
            if (!battle_IsPlayerPhase() || battle_IsPlayerDefeated()) return;
            if (conditions_summon_IsActive()) return;
        }
    }

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck != noone) {
        with (_deck) {
            if (deck_AnyPickerOpen()) return;
        }
    }
    
    if (_deck != noone) {
        with (_deck) {
            if (deck_AnyPickerOpen()) return;
        }
    }

    if (mouse_check_button_pressed(mb_right)) {
        if (is_dragging) SCR_DragDrop_Cancel();
    }
    
    if (mouse_check_button_pressed(mb_left) && !is_dragging) {
        if (_targeting) return;

        var _hand = instance_find(OBJ_Hand, 0);
        if (_hand == noone) return;

        var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
        var _picked = SCR_Hand_PickCardIndex(_mx, _my, _hand.hand_Count, _spacing, _hand.hand_Y);

        if (_picked >= 0) {
            drag_card       = _hand.hand[_picked];
            drag_hand_index = _picked;
            drag_x          = _mx;
            drag_y          = _my;
            is_dragging     = true;
}
    }
    
    if (is_dragging) {
        if (_targeting) {
            if (mouse_check_button_released(mb_left)) SCR_DragDrop_Cancel();
            return;
        }

        drag_x = _mx;
        drag_y = _my;
        SCR_Board_UpdateHover(_mx, _my, drag_card, drag_hand_index);
        
        if (mouse_check_button_released(mb_left)) {
            var _slot = SCR_Board_GetSlotAt(_mx, _my);
            
            if (_slot != undefined) {
                if (!variable_struct_exists(_slot, "locked")) {
                    _slot.locked = false;
                }
                if (!_slot.occupied && !_slot.locked) {
                    if (!card_CanAffordAllCosts(drag_card, drag_hand_index)) {
} else if (SCR_Board_PlaceCard(_slot, drag_card)) {
                        card_PayAllCosts(drag_card, drag_hand_index);
                        var _hand = instance_find(OBJ_Hand, 0);
                        if (_hand != noone) {
                            var _index = drag_hand_index;
                            with (_hand) {
                                hand_RemoveCard(_index);
                            }
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
    
    card_DrawFramedAtCenter(drag_x, drag_y, 1.1, drag_card, 0.85);
    draw_set_color(c_black);
    draw_set_halign(fa_center);
    draw_text(drag_x, drag_y - 60, drag_card.name);
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}
function SCR_DragDrop_Cancel() {
    drag_card       = undefined;
    drag_hand_index = -1;
    is_dragging     = false;
    SCR_Board_ClearHover();
}