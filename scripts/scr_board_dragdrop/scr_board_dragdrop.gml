/// @desc Drag cards from hand onto the board (pays costs on drop)

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
            var _target = SCR_Board_GetDropTarget(_mx, _my, drag_card);
            if (_target != undefined) SCR_Board_PlayCardFromHand(_target, drag_card, drag_hand_index);
            SCR_DragDrop_Cancel();
        }
    }
}

/// Play a hand card onto a drop target { slot, monster }. The cost is paid first; if the card cannot be
/// placed it is refunded. An action card keeps its receipt so cancelling it unused refunds the cost.
/// Returns true when the card was played.
function SCR_Board_PlayCardFromHand(_target, _card, _hand_index) {
    if (_target == undefined || _card == undefined) return false;
    var _slot = _target.slot;
    if (_slot == undefined) return false;
    if (!variable_struct_exists(_slot, "locked")) _slot.locked = false;
    if (_slot.occupied || _slot.locked) return false;

    if (!card_CanAffordAllCosts(_card, _hand_index)) {
        battle_EnemyLog_Write("Can't play " + _card.name + ": its cost isn't met.");
        return false;
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    global.card_last_payment = undefined;
    if (!card_PayAllCosts(_card, _hand_index)) return false;
    var _receipt = global.card_last_payment;

    // the card leaves the hand, found by reference (paying tributes may have shifted the hand)
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand != noone) {
        with (_hand) {
            var _index = hand_IndexOf(_card);
            if (_index >= 0) hand_RemoveCard(_index);
        }
    }

    if (_slot.type == "action" && _bm != noone) {
        with (_bm) action_payment = _receipt;
    }

    if (!SCR_Board_PlaceCard(_slot, _card)) {
        card_RefundPayment(_receipt);
        if (_hand != noone) with (_hand) hand_AddCard(_card);
        if (_bm != noone) with (_bm) action_payment = undefined;
        return false;
    }

    // an action dropped on a monster: that monster is the one that acts
    if (_slot.type == "action" && _target.monster >= 0 && _bm != noone) {
        var _actor = _target.monster;
        with (_bm) {
            if (target_mode == "pick_player_monster") battle_TargetingClickPlayerSlot(_actor);
        }
    }
    return true;
}

function SCR_DragDrop_Draw() {
    if (!is_dragging || drag_card == undefined) return;

    // over a monster that can take it: the card shrinks onto that monster's corner
    var _target = SCR_Board_GetDropTarget(drag_x, drag_y, drag_card);
    if (_target != undefined && !SCR_Board_IsMonsterCard(drag_card)) {
        var _ms = player_monster_slots[_target.monster];
        card_DrawFramedAtCenter(_ms.x + _ms.w * 1.02, _ms.y + 8, 0.62, drag_card, 1);
        return;
    }

    card_DrawFramedAtCenter(drag_x, drag_y, 1.1, drag_card, 0.85);
    draw_set_halign(fa_center);
    battle_DrawOutlinedText(drag_x, drag_y - 66, drag_card.name, c_white);
    var _hint = "Drop on the monster that should act";
    if (SCR_Board_IsMonsterCard(drag_card)) _hint = "Drop on a lit spot";
    else if (drag_card.type == "weapon") _hint = "Drop on one of your monsters to arm it";
    battle_DrawOutlinedText(room_width / 2, 8, _hint, make_color_rgb(239, 227, 196));
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

function SCR_DragDrop_Cancel() {
    drag_card       = undefined;
    drag_hand_index = -1;
    is_dragging     = false;
    SCR_Board_ClearHover();
}
