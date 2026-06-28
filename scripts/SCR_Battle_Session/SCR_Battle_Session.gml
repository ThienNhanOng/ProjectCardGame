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

function battle_PermanentlyLoseSpirit(_card) {
    if (_card == undefined || !battle_IsSpiritMonster(_card)) return false;
    if (card_IsAstral(_card)) {
        show_debug_message(_card.name + " astral spirit dismissed (not removed from collection)");
        return false;
    }
    if (!variable_struct_exists(_card, "id")) return false;

    var _card_id = floor(real(_card.id));
    if (_card_id <= 0) return false;

    collection_RemoveOwnedCopy(_card_id, 1);
    show_debug_message(_card.name + " spirit lost permanently");
    return true;
}

/// @desc After a fight, extra deck source = cards still in extra deck + spirits still alive on board.
function battle_SyncExtraDeckFromBattleState() {
    var _extra_ids = [];

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck != noone) {
        with (_deck) {
            for (var i = 0; i < extra_deck_Count; i++) {
                var _id = extra_deck[i];
                if (card_IsAstral(_id)) continue;
                array_push(_extra_ids, _id);
            }
        }
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone) {
        for (var s = 0; s < array_length(_board.player_monster_slots); s++) {
            var _slot = _board.player_monster_slots[s];
            if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
            if (!battle_IsSpiritMonster(_slot.card)) continue;
            if (card_IsAstral(_slot.card)) continue;
            if (!variable_struct_exists(_slot.card, "id")) continue;
            array_push(_extra_ids, floor(real(_slot.card.id)));
        }
    }

    battle_SaveDeckSources(battle_GetDeckSourceCopy(), _extra_ids);
    show_debug_message("Extra deck synced: " + string(array_length(_extra_ids))
        + " persistent spirit copy/copies for next fight");
}

/// @desc Called when leaving Room_battle back to the map
function battle_EndSession() {
    global.battle_runtime_config = undefined;
    show_debug_message("Battle session ended — deck sources preserved for next fight");
}
