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
            var _entry = extraDeck_NormalizeEntry(global.battle_extra_deck_source[i]);
            if (_entry != undefined) array_push(_copy, _entry);
        }
    }
    return _copy;
}

function extraDeck_GetCardId(_entry) {
    if (_entry == undefined) return -1;
    if (is_struct(_entry)) {
        if (variable_struct_exists(_entry, "id")) return floor(real(_entry.id));
        if (variable_struct_exists(_entry, "card_id")) return floor(real(_entry.card_id));
    }
    return floor(real(_entry));
}

function extraDeck_GetAstralRemaining(_entry) {
    if (_entry == undefined) return 0;
    if (is_struct(_entry) && variable_struct_exists(_entry, "astral_remaining")) {
        return max(0, floor(_entry.astral_remaining));
    }
    return card_GetAstralSummonLimit(extraDeck_GetCardId(_entry));
}

function extraDeck_CreateEntry(_card_id, _astral_remaining = undefined) {
    _card_id = floor(real(_card_id));
    if (_card_id <= 0) return undefined;

    if (_astral_remaining == undefined) {
        _astral_remaining = card_GetAstralSummonLimit(_card_id);
    } else {
        _astral_remaining = max(0, floor(_astral_remaining));
    }

    return {
        id: _card_id,
        astral_remaining: _astral_remaining
    };
}

function extraDeck_NormalizeEntry(_raw) {
    if (_raw == undefined) return undefined;

    if (is_struct(_raw)) {
        var _id = extraDeck_GetCardId(_raw);
        if (_id <= 0) return undefined;

        var _remaining = extraDeck_GetAstralRemaining(_raw);
        if (!variable_struct_exists(_raw, "astral_remaining")) {
            _remaining = card_GetAstralSummonLimit(_id);
        }
        return extraDeck_CreateEntry(_id, _remaining);
    }

    return extraDeck_CreateEntry(_raw);
}

function extraDeck_EntryFromRuntimeCard(_card) {
    if (_card == undefined || !variable_struct_exists(_card, "id")) return undefined;

    var _id = floor(real(_card.id));
    var _remaining = 0;
    if (variable_struct_exists(_card, "astral_remaining")) {
        _remaining = max(0, floor(_card.astral_remaining));
    }
    return extraDeck_CreateEntry(_id, _remaining);
}

function card_GetAstralSummonLimit(_card_or_id) {
    var _def = undefined;

    if (is_struct(_card_or_id)) {
        if (variable_struct_exists(_card_or_id, "id")) {
            _def = deck_GetCardData(_card_or_id.id);
        } else {
            _def = _card_or_id;
        }
    } else {
        _def = deck_GetCardData(floor(_card_or_id));
    }

    if (_def == undefined) return 0;

    if (variable_struct_exists(_def, "astral")) {
        if (is_bool(_def.astral) && _def.astral) return 1;
        if (is_real(_def.astral) && _def.astral > 0) return floor(_def.astral);
    }

    var _reqs = conditions_GetRequirements(_def);
    for (var i = 0; i < array_length(_reqs); i++) {
        if (_reqs[i].type == "astral") return max(1, _reqs[i].amount);
    }
    return 0;
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

function battle_PermanentlyRemoveSpiritById(_card_id) {
    _card_id = floor(real(_card_id));
    if (_card_id <= 0) return false;

    collection_RemoveOwnedCopy(_card_id, 1);
    battle_SyncExtraDeckFromBattleState();
    show_debug_message("Spirit id " + string(_card_id) + " removed permanently");
    return true;
}

function battle_PermanentlyRemoveSpiritEntry(_entry) {
    if (_entry == undefined) return false;
    return battle_PermanentlyRemoveSpiritById(extraDeck_GetCardId(_entry));
}

function battle_PermanentlyLoseSpirit(_card) {
    if (_card == undefined || !battle_IsSpiritMonster(_card)) return false;
    if (!variable_struct_exists(_card, "id")) return false;

    var _card_id = floor(real(_card.id));
    if (_card_id <= 0) return false;

    if (variable_struct_exists(_card, "spirit_expired") && _card.spirit_expired) {
        show_debug_message(_card.name + " expired spirit leaves the board");
        return true;
    }

    battle_PermanentlyRemoveSpiritById(_card_id);
    show_debug_message(_card.name + " spirit lost permanently");
    return true;
}

/// @desc After a fight, extra deck source = cards still in extra deck + spirits still alive on board.
function battle_SyncExtraDeckFromBattleState() {
    var _extra_entries = [];

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck != noone) {
        with (_deck) {
            for (var i = 0; i < extra_deck_Count; i++) {
                var _entry = extraDeck_NormalizeEntry(extra_deck[i]);
                if (_entry == undefined) continue;
                if (extraDeck_GetAstralRemaining(_entry) == 0 && card_GetAstralSummonLimit(_entry) > 0) continue;
                array_push(_extra_entries, _entry);
            }
        }
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone) {
        for (var s = 0; s < array_length(_board.player_monster_slots); s++) {
            var _slot = _board.player_monster_slots[s];
            if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
            if (!battle_IsSpiritMonster(_slot.card)) continue;
            if (variable_struct_exists(_slot.card, "spirit_expired") && _slot.card.spirit_expired) continue;
            if (variable_struct_exists(_slot.card, "astral_remaining") && _slot.card.astral_remaining <= 0
                && card_GetAstralSummonLimit(_slot.card) > 0) {
                continue;
            }

            var _entry = extraDeck_EntryFromRuntimeCard(_slot.card);
            if (_entry != undefined) array_push(_extra_entries, _entry);
        }
    }

    battle_SaveDeckSources(battle_GetDeckSourceCopy(), _extra_entries);
    show_debug_message("Extra deck synced: " + string(array_length(_extra_entries))
        + " spirit copy/copies for next fight");
}

/// @desc Called when leaving Room_battle back to the map
function battle_EndSession() {
    global.battle_runtime_config = undefined;
    show_debug_message("Battle session ended — deck sources preserved for next fight");
}
