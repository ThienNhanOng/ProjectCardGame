event_inherited();
eventmarker_apply_config(2, "Crossroads", "battle02", "Grasslands_Battleset01_starter.json", "battle02,battle03,battle04");

eventmarker_set_dialog_pre(dialog_Map1_Marker02_PreBattle);
eventmarker_set_dialog_pre_once(true);

// TEST DEBUG: win battle here, then go to Map 2
eventmarker_set_room_goto("Room_Worldmap2");
