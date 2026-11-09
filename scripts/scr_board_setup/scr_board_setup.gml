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
        // the slot box ends at the enemy's feet (scr_battle_layout)
        var _feet = battle_LayoutEnemyFeet(i);
        var _x = _feet.x - board_card_w / 2;
        enemy_y = _feet.y + 5 - board_card_h;
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
    // front column 0-2 (open), back column 3-4 (hidden zones, unlocked by abilities) — scr_battle_layout
    for (var i = 0; i < 5; i++) {
        var _c = battle_LayoutPlayerSlotCentre(i);
        _slots[i] = SCR_SlotFactory_CreateMonsterSlot(i, _c.x - BATTLE_CARD_W / 2, _c.y - BATTLE_CARD_H / 2, i < 3, i >= 3);
        _slots[i].w = BATTLE_CARD_W;
        _slots[i].h = BATTLE_CARD_H;
    }
    return _slots;
}

function SCR_Board_DefineWeaponSlots() {
    var _slots = [];
    // weapon slot i sits on monster slot i: you drop the weapon on the monster
    for (var i = 0; i < 5; i++) {
        var _c = battle_LayoutPlayerSlotCentre(i);
        _slots[i] = SCR_SlotFactory_CreateWeaponSlot(i, _c.x - BATTLE_CARD_W / 2, _c.y - BATTLE_CARD_H / 2, i < 3, i >= 3);
        _slots[i].w = BATTLE_CARD_W;
        _slots[i].h = BATTLE_CARD_H;
    }
    return _slots;
}

function SCR_Board_DefineActionSlot() {
    // only shows while an action card is resolving; you drop actions on a monster
    return SCR_SlotFactory_CreateActionSlot(604, 390);
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
