if (variable_global_exists("spawn_x") && variable_global_exists("spawn_y")) {
    if (is_real(global.spawn_x) && is_real(global.spawn_y)) {
        x = global.spawn_x;
        y = global.spawn_y;
        global.spawn_x = undefined;
        global.spawn_y = undefined;
    }
}
