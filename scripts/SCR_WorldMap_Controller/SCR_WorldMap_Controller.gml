/// @desc Initializes world map progression for the current map room

function SCR_WorldMapController_Init() {
    // The room decides its map file (worldmap_GetRoomConfigFile). Room creation code cannot set it:
    // GameMaker runs room creation code AFTER the instances' Create events.
    worldmap_InitRoom(worldmap_GetRoomConfigFile());
    worldmap_ApplyPendingPlayerSpawn();
    dialog_Init();
    dialog_TryRunPendingPost();
    save_Autosave();   // slot 1: every time you arrive on a map (after a battle, the deck builder, a new map)
}

function SCR_WorldMapController_Step() {
    if (!instance_exists(OBJ_DialogController)) {
        instance_create_depth(0, 0, -10000, OBJ_DialogController);
    }

    dialog_Step();

    if (dialog_IsActive()) return;

    worldmap_RefreshAllMarkers();
    worldmap_HandleCollectionButton();
    worldmap_HandleMenuButton();
}

function SCR_WorldMapController_DrawHUD() {
    if (dialog_IsActive()) return;

    worldmap_InitGlobals();

    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();

    debug_DrawWorldMapInfo(_gw, _gh);
    worldmap_DrawMapDebugInfo(_gh);
    worldmap_DrawCollectionButton();
    worldmap_DrawMenuButton();
    worldmap_NodeDrawHint();
    worldmap_NodeDrawConfirm();   // "Are you sure you want to go here?" on top of everything
}
