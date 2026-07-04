function SCR_Board_PlayerSlots() {
    player_monster_start_x = 20;
    player_monster_y = 430;
    player_weapon_offset_y = 60;
    
    player_monster_slots = [];
    for (var i = 0; i < 5; i++) {
        var _x = player_monster_start_x + i * (board_card_w + board_padding);
        array_push(player_monster_slots, {
            index    : i,
            type     : "monster",
            owner    : "player",
            occupied : false,
            card     : undefined,
            x        : _x,
            y        : player_monster_y,
            w        : board_card_w,
            h        : board_card_h,
            visible  : (i < 3),
            locked   : (i >= 3),
            hovered  : false
        });
    }
    
    player_weapon_slots = [];
    for (var i = 0; i < 5; i++) {
        var _x = player_monster_start_x + i * (board_card_w + board_padding);
        var _y = player_monster_y + player_weapon_offset_y;
        array_push(player_weapon_slots, {
            index    : i,
            type     : "weapon",
            owner    : "player",
            occupied : false,
            card     : undefined,
            x        : _x,
            y        : _y,
            w        : board_card_w,
            h        : board_card_h,
            visible  : (i < 3),
            locked   : (i >= 3),
            hovered  : false
        });
    }
    
}