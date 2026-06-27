/// @desc Handle READY button click to return to the map that opened collection

if (!mouse_check_button_pressed(mb_left)) return;

if (mouse_x <= room_width - 150 || mouse_x >= room_width - 20
    || mouse_y <= room_height - 100 || mouse_y >= room_height - 60) {
    return;
}

if (array_length(selected_deck) < 8) {
    show_debug_message("Need at least 8 cards to start! Current: " + string(array_length(selected_deck)));
    return;
}

var _main_ids = player_deck_SaveSelectedDeckIds();

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
room_goto(worldmap_GetCollectionReturnRoom());
