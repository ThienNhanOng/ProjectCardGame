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