/// @desc Enemy slot positions on OBJ_BoardManager (called from SCR_Board_Create)
/// board_card_w / board_card_h / board_padding come from SCR_Board_Dimensions (board_padding = 10, used on player side)

function SCR_Board_EnemySlots() {
    enemy_start_x = 100;
    enemy_y = 60;
    enemy_slot_spacing = 75;

    enemy_slots = [];
    for (var i = 0; i < 3; i++) {
        var _x = enemy_start_x + i * (board_card_w + enemy_slot_spacing);
        array_push(enemy_slots, {
            index    : i,
            type     : "monster",
            owner    : "enemy",
            occupied : false,
            card     : undefined,
            x        : _x,
            y        : enemy_y,
            w        : board_card_w,
            h        : board_card_h,
            visible  : false,
            locked   : false,
            hovered  : false
        });
    }

}
