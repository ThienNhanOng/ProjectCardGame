// Reset battle session globals before instances spawn (reuses this room for every event)
battle_BeginSession();

// ===== PLAY ROOM CAMERA SETUP =====

// Enable viewports
view_enabled = true;
view_visible[0] = true;

// Get or create camera
var _cam = view_camera[0];
if (_cam == -1) {
    _cam = camera_create();
    view_camera[0] = _cam;
}

// ===== CHANGE THIS VALUE TO MOVE =====
camera_set_view_pos(_cam, -100, 0);  // ← Change this number!

camera_set_view_size(_cam, 1280, 700);
view_set_wport(0, 1280);
view_set_hport(0, 700);
view_set_xport(0, 0);
view_set_yport(0, 0);
view_set_camera(0, _cam);

