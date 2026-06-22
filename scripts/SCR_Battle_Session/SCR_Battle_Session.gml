/// @desc Reusable battle room session — reset deck, health, and runtime state each fight

function battle_SaveDeckSources(_main_ids, _extra_ids) {
    global.battle_deck_source = [];
    for (var i = 0; i < array_length(_main_ids); i++) {
        array_push(global.battle_deck_source, _main_ids[i]);
    }

    global.battle_extra_deck_source = [];
    for (var i = 0; i < array_length(_extra_ids); i++) {
        array_push(global.battle_extra_deck_source, _extra_ids[i]);
    }

    show_debug_message("Battle deck source saved: "
        + string(array_length(global.battle_deck_source))
        + " main, "
        + string(array_length(global.battle_extra_deck_source))
        + " extra");
}

function battle_MigrateLegacyDeckSources() {
    if ((!variable_global_exists("battle_deck_source")
            || !is_array(global.battle_deck_source)
            || array_length(global.battle_deck_source) <= 0)
        && variable_global_exists("battle_deck")
        && is_array(global.battle_deck)
        && array_length(global.battle_deck) > 0) {
        global.battle_deck_source = [];
        for (var i = 0; i < array_length(global.battle_deck); i++) {
            array_push(global.battle_deck_source, global.battle_deck[i]);
        }
    }

    if ((!variable_global_exists("battle_extra_deck_source")
            || !is_array(global.battle_extra_deck_source)
            || array_length(global.battle_extra_deck_source) <= 0)
        && variable_global_exists("battle_extra_deck")
        && is_array(global.battle_extra_deck)
        && array_length(global.battle_extra_deck) > 0) {
        global.battle_extra_deck_source = [];
        for (var i = 0; i < array_length(global.battle_extra_deck); i++) {
            array_push(global.battle_extra_deck_source, global.battle_extra_deck[i]);
        }
    }
}

function battle_GetDeckSourceCopy() {
    battle_MigrateLegacyDeckSources();

    var _copy = [];
    if (variable_global_exists("battle_deck_source")
        && is_array(global.battle_deck_source)) {
        for (var i = 0; i < array_length(global.battle_deck_source); i++) {
            array_push(_copy, global.battle_deck_source[i]);
        }
    }
    return _copy;
}

function battle_GetExtraDeckSourceCopy() {
    battle_MigrateLegacyDeckSources();

    var _copy = [];
    if (variable_global_exists("battle_extra_deck_source")
        && is_array(global.battle_extra_deck_source)) {
        for (var i = 0; i < array_length(global.battle_extra_deck_source); i++) {
            array_push(_copy, global.battle_extra_deck_source[i]);
        }
    }
    return _copy;
}

/// @desc Called from Room_battle creation code before instances spawn
function battle_BeginSession() {
    battle_MigrateLegacyDeckSources();
    global.battleset_cache = {};

    battle_EnsureMonsterDatabase();

    if (!variable_global_exists("battle_session_count")) {
        global.battle_session_count = 0;
    }
    global.battle_session_count++;

    show_debug_message("Battle session #" + string(global.battle_session_count) + " starting");
}

/// @desc Called when leaving Room_battle back to the map
function battle_EndSession() {
    global.battle_runtime_config = undefined;
    show_debug_message("Battle session ended — deck sources preserved for next fight");
}
