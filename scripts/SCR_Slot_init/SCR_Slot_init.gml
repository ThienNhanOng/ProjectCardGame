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