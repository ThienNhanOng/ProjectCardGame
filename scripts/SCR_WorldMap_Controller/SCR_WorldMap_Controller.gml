/// @desc Initializes grasslands world map progression for this room

function SCR_WorldMapController_Init() {
    worldmap_InitRoom("Grasslands_WorldMap01.json");
}

function SCR_WorldMapController_Step() {
    worldmap_RefreshAllMarkers();
}

function SCR_WorldMapController_DrawHUD() {
    worldmap_InitGlobals();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(12, room_height - 72, "Map: " + global.worldmap.map_id);
    draw_text(12, room_height - 56, "Progress: " + string(array_length(global.worldmap.cleared))
        + " / " + string(array_length(global.worldmap.event_flow)));
    draw_text(12, room_height - 40, "WASD move | E interact at active markers");
    draw_set_color(c_white);
}
