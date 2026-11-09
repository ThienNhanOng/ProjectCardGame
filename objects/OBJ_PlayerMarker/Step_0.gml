worldmap_PlayerMovementStep(id);

if (keyboard_check_pressed(ord("E")) || keyboard_check_pressed(vk_enter)) {
    worldmap_TryPlayerInteract(id);
}
