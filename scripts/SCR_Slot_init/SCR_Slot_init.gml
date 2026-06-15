/// @description Define all slot positions

function SCR_Board_DefineMonsterSlots() {
    var _slots = [];
    // (index, x, y, visible, locked)
    _slots[0] = SCR_SlotFactory_CreateMonsterSlot(0, 53, 395, true, false);
    _slots[1] = SCR_SlotFactory_CreateMonsterSlot(1, 131.5, 395, true, false);
    _slots[2] = SCR_SlotFactory_CreateMonsterSlot(2, 209, 395, true, false);
    _slots[3] = SCR_SlotFactory_CreateMonsterSlot(3, 288, 395, false, true);
    _slots[4] = SCR_SlotFactory_CreateMonsterSlot(4, 367, 395, false, true);
    return _slots;
}

function SCR_Board_DefineWeaponSlots() {
    var _slots = [];
    // (index, x, y, visible, locked)
    _slots[0] = SCR_SlotFactory_CreateWeaponSlot(0, 53, 478, true, false);
    _slots[1] = SCR_SlotFactory_CreateWeaponSlot(1, 131.5, 478, true, false);
    _slots[2] = SCR_SlotFactory_CreateWeaponSlot(2, 209, 478, true, false);
    _slots[3] = SCR_SlotFactory_CreateWeaponSlot(3, 288, 478, false, true);
    _slots[4] = SCR_SlotFactory_CreateWeaponSlot(4, 367, 478, false, true);
    return _slots;
}

function SCR_Board_DefineActionSlot() {
    return SCR_SlotFactory_CreateActionSlot(457, 445);
}