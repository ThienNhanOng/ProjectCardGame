/// @desc Handle READY button click to start the game

// Check if READY button was clicked
if (mouse_x > room_width - 150 && mouse_x < room_width - 20 &&
    mouse_y > room_height - 100 && mouse_y < room_height - 60) {
    
    // Verify deck has minimum 8 cards
    if (array_length(selected_deck) >= 8) {
        
        var _main_ids = [];
        for (var i = 0; i < array_length(selected_deck); i++) {
            array_push(_main_ids, selected_deck[i].id);
        }

        var _extra_ids = [];
        for (var s = 0; s < array_length(global.player_collection); s++) {
            var _spirit = global.player_collection[s];
            if (_spirit.type != "spirit" && _spirit.type != "special_monster") continue;

            var _owned = variable_struct_exists(_spirit, "owned") ? _spirit.owned : 0;
            for (var c = 0; c < _owned; c++) {
                array_push(_extra_ids, _spirit.id);
            }
        }

        battle_SaveDeckSources(_main_ids, _extra_ids);
        
        // Transition to battle room
        room_goto(Room_Worldmap1);  // ← Use your actual room name
        
    } else {
        show_debug_message("Need at least 8 cards to start! Current: " + string(array_length(selected_deck)));
    }
}