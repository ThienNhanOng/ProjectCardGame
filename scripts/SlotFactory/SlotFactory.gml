/// @description Slot Factory

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