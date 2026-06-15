function SCR_Board_Create() {
    SCR_Board_Dimensions();
    SCR_Board_PlayerSlots();
    SCR_Board_EnemySlots();
    SCR_Board_ActionSlot();
    
    show_debug_message("Board initialized.");
}