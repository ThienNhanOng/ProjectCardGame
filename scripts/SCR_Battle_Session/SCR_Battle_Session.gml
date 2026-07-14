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

/// @desc Clone of the main deck at battle start (spirit shuffle refill source)
function battle_GetInitialMainDeckCopy() {
    var _copy = [];
    if (variable_global_exists("battle_initial_main_deck")
        && is_array(global.battle_initial_main_deck)) {
        for (var i = 0; i < array_length(global.battle_initial_main_deck); i++) {
            array_push(_copy, global.battle_initial_main_deck[i]);
        }
    }

    if (array_length(_copy) > 0) return _copy;
    return battle_GetDeckSourceCopy();
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

function extraDeck_CreateEntry(_card_id) {
    _card_id = floor(real(_card_id));
    if (_card_id <= 0) return undefined;
    return { id: _card_id };
}

function extraDeck_NormalizeEntry(_raw) {
    if (_raw == undefined) return undefined;

    if (is_struct(_raw)) {
        var _id = extraDeck_GetCardId(_raw);
        if (_id <= 0) return undefined;
        return extraDeck_CreateEntry(_id);
    }

    return extraDeck_CreateEntry(_raw);
}

function extraDeck_EntryFromRuntimeCard(_card) {
    if (_card == undefined || !variable_struct_exists(_card, "id")) return undefined;
    if (!card_IsAstral(_card)) return undefined;
    return extraDeck_CreateEntry(_card.id);
}

/// @desc True when a spirit card has the astral condition (persists in extra deck unless it dies)
function card_HasAstralCondition(_card_or_id) {
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

    if (_def == undefined) return false;

    if (variable_struct_exists(_def, "astral")) {
        if (is_bool(_def.astral) && _def.astral) return true;
        if (is_real(_def.astral) && _def.astral > 0) return true;
    }

    var _reqs = conditions_GetRequirements(_def);
    for (var i = 0; i < array_length(_reqs); i++) {
        if (_reqs[i].type == "astral") return true;
    }
    return false;
}

/// @desc Called from Room_battle creation code before instances spawn
function battle_BeginSession() {
    battle_MigrateLegacyDeckSources();
    global.battleset_cache = {};
    global.battle_initial_main_deck = battle_GetDeckSourceCopy();

    battle_EnsureMonsterDatabase();

    if (!variable_global_exists("battle_session_count")) {
        global.battle_session_count = 0;
    }
    global.battle_session_count++;

}

function battle_PermanentlyRemoveSpiritById(_card_id) {
    _card_id = floor(real(_card_id));
    if (_card_id <= 0) return false;

    collection_RemoveOwnedCopy(_card_id, 1);
    battle_SyncExtraDeckFromBattleState();
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
return true;
    }

    if (variable_struct_exists(_card, "spirit_temp_consumed") && _card.spirit_temp_consumed) {
        return true;
    }

    battle_PermanentlyRemoveSpiritById(_card_id);
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
            if (variable_struct_exists(_slot.card, "spirit_temp_consumed") && _slot.card.spirit_temp_consumed) continue;
            if (!card_IsAstral(_slot.card)) continue;

            var _entry = extraDeck_EntryFromRuntimeCard(_slot.card);
            if (_entry != undefined) array_push(_extra_entries, _entry);
        }
    }

    battle_SaveDeckSources(battle_GetDeckSourceCopy(), _extra_entries);
}

/// @desc Called when leaving Room_battle back to the map
function battle_EndSession() {
    global.battle_runtime_config = undefined;
}
