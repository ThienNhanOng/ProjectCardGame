/// @desc Initializes world map progression for the current map room

function SCR_WorldMapController_Init() {
    var _config = worldmap_GetRoomConfigFile();
    if (variable_global_exists("worldmap_room_config_file")
        && is_string(global.worldmap_room_config_file)
        && global.worldmap_room_config_file != "") {
        _config = global.worldmap_room_config_file;
    }
    worldmap_InitRoom(_config);
    worldmap_ApplyPendingPlayerSpawn();
    dialog_Init();
    dialog_TryRunPendingPost();
}

function SCR_WorldMapController_Step() {
    if (!instance_exists(OBJ_DialogController)) {
        instance_create_depth(0, 0, -10000, OBJ_DialogController);
    }

    dialog_Step();

    if (dialog_IsActive()) return;

    worldmap_RefreshAllMarkers();
    worldmap_HandleCollectionButton();
}

function SCR_WorldMapController_DrawHUD() {
    if (dialog_IsActive()) return;

    worldmap_InitGlobals();

    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(12, _gh - 72, "Map: " + global.worldmap.map_id);
    draw_text(12, _gh - 56, "Progress: " + string(array_length(global.worldmap.cleared))
        + " / " + string(array_length(global.worldmap.event_flow)));
    draw_text(12, _gh - 40, "WASD move | E interact at active markers");
    draw_set_color(c_white);

    worldmap_DrawCollectionButton();
}
