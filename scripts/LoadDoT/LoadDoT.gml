/// @desc Built-in DoT definitions (no external JSON required)

function SCR_LoadAllDoT() {
    dot_DB = {};
    dot_RegisterBuiltin("burn", "Burn", 2, 2);
    dot_RegisterBuiltin("poison", "Poison", 1, 3);
    dot_RegisterBuiltin("electrocuted", "Shock", 2, 2);
    show_debug_message("DoT types loaded: " + string(variable_struct_names_count(dot_DB)));
}

function dot_RegisterBuiltin(_type, _label, _damage, _duration) {
    dot_DB[$ _type] = {
        dot_type: _type,
        label: _label,
        damage_per_tick: _damage,
        default_duration: _duration
    };
}

function dot_GetDefinition(_dot_type) {
    if (!variable_global_exists("dot_DB")) return undefined;
    if (!variable_struct_exists(dot_DB, _dot_type)) {
        show_debug_message("DoT type not found: " + _dot_type);
        return undefined;
    }
    return dot_DB[$ _dot_type];
}
