function SCR_Board_ActionSlot() {
    action_slot_x = 605;
    action_slot_y = 390;
    
    action_slot = {
        index    : 0,
        type     : "action",
        owner    : "player",
        occupied : false,
        card     : undefined,
        x        : action_slot_x,
        y        : action_slot_y,
        w        : board_card_w,
        h        : board_card_h,
        visible  : true,
        hovered  : false
    };
    
    show_debug_message("Action slot initialized.");
}