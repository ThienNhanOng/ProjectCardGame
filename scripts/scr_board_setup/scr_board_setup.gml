/// @desc OBJ_BoardManager Create — slot layout and slot factories

function SCR_Board_Create() {
    SCR_Board_Dimensions();
    
    // Use your factory definitions, NOT SCR_Board_InitSlots()
    player_monster_slots = SCR_Board_DefineMonsterSlots();
    player_weapon_slots = SCR_Board_DefineWeaponSlots();
    action_slot = SCR_Board_DefineActionSlot();
    
    // Initialize weapon slot availability
    SCR_Board_UpdateWeaponSlotAvailability();
    
    SCR_Board_EnemySlots();
    
}

function SCR_Board_Dimensions() {
    board_card_w = 73;
    board_card_h = 101;
    board_padding = 10;
}

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

/// @description Define all slot positions
function SCR_Board_DefineMonsterSlots() {
    var _slots = [];
    // (index, x, y, visible, locked)
    _slots[0] = SCR_SlotFactory_CreateMonsterSlot(0, 16, 342, true, false);
    _slots[1] = SCR_SlotFactory_CreateMonsterSlot(1, 94, 342, true, false);
    _slots[2] = SCR_SlotFactory_CreateMonsterSlot(2, 172, 342, true, false);
    _slots[3] = SCR_SlotFactory_CreateMonsterSlot(3, 250, 342, false, true);
    _slots[4] = SCR_SlotFactory_CreateMonsterSlot(4, 328, 342, false, true);
    return _slots;
}

function SCR_Board_DefineWeaponSlots() {
    var _slots = [];
    // (index, x, y, visible, locked)
    _slots[0] = SCR_SlotFactory_CreateWeaponSlot(0, 16, 428, true, false);
    _slots[1] = SCR_SlotFactory_CreateWeaponSlot(1, 94, 428, true, false);
    _slots[2] = SCR_SlotFactory_CreateWeaponSlot(2, 172, 428, true, false);
    _slots[3] = SCR_SlotFactory_CreateWeaponSlot(3, 250, 428, false, true);
    _slots[4] = SCR_SlotFactory_CreateWeaponSlot(4, 328, 428, false, true);
    return _slots;
}

function SCR_Board_DefineActionSlot() {
    return SCR_SlotFactory_CreateActionSlot(420, 394);
}

function SCR_SlotFactory_CreateMonsterSlot(_index, _x, _y, _visible, _locked) {
    return {
        index    : _index,
        type     : "monster",
        owner    : "player",
        occupied : false,
        card     : undefined,
        x        : _x,
        y        : _y,
        w        : 73,
        h        : 101,
        visible  : _visible,
        locked   : _locked,  // ← CRITICAL
        hovered  : false,
        sprite   : SPR_MonsterSlot
    };
}

function SCR_SlotFactory_CreateWeaponSlot(_index, _x, _y, _visible, _locked) {
    return {
        index    : _index,
        type     : "weapon",
        owner    : "player",
        occupied : false,
        card     : undefined,
        x        : _x,
        y        : _y,
        w        : 73,
        h        : 101,
        visible  : _visible,
        locked   : _locked,  // ← CRITICAL
        hovered  : false,
        sprite   : SPR_WeaponSlot
    };
}

function SCR_SlotFactory_CreateActionSlot(_x, _y) {
    return {
        index    : 0,
        type     : "action",
        owner    : "player",
        occupied : false,
        card     : undefined,
        x        : _x,
        y        : _y,
        w        : 73,
        h        : 101,
        visible  : true,
        locked   : false,    
        hovered  : false,
        sprite   : SPR_ActionSlot
    };
}
