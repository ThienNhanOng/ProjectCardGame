// --- Movement (WASD) ---
var move_spd = 4;

var hor = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var ver = keyboard_check(ord("S")) - keyboard_check(ord("W"));

x += hor * move_spd;
y += ver * move_spd;

// --- Keep player inside the map ---
x = clamp(x, 120, 1245);
y = clamp(y, 160, 650);

// --- Interact (E) with nearest available event ---
if (keyboard_check_pressed(ord("E"))) {
    worldmap_TryPlayerInteract(id);
}
