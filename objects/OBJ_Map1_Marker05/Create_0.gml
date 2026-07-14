event_inherited();
eventmarker_apply_config(5, "Boss Gate", "battle05", "Grasslands_Battleset01_starter.json", "battle05,battle06,battle07,battle08");

eventmarker_set_dialog_pre(dialog_Map1_Marker05_PreBattle);
eventmarker_set_dialog_pre_once(true);

// TEST DEBUG: win battle here, then go to Map 2 event 1 (Grass Trail)
eventmarker_set_room_goto("Room_Worldmap2", 1);
