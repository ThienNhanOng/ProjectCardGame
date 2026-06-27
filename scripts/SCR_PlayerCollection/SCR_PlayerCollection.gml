// ===== PLAYER COLLECTION =====

// card_DB               — full card pool (all JSON definitions). Not player-owned.

// global.player_collection — cards the player owns (owned count).

// JSON "own" grants starting copies once. Map markers & traits add more via AddCardToCollection.



if (!variable_global_exists("player_collection") || !is_array(global.player_collection)) {

    global.player_collection = [];

}



function collection_CopyDefinition(_template) {

    if (_template == undefined) return undefined;



    var _card = {};

    var _keys = variable_struct_get_names(_template);

    for (var i = 0; i < array_length(_keys); i++) {

        var _key = _keys[i];

        if (_key == "owned" || _key == "own") continue;

        _card[$ _key] = _template[$ _key];

    }

    return _card;

}



function collection_FindDefinition(_card_id, _collection = "") {

    var _fallback = undefined;



    for (var i = 0; i < array_length(card_DB.cards); i++) {

        var _def = card_DB.cards[i];

        if (_def.id != _card_id) continue;



        if (_fallback == undefined) _fallback = _def;



        if (_collection != ""

            && variable_struct_exists(_def, "collection")

            && _def.collection == _collection) {

            return _def;

        }

    }



    return _fallback;

}



function collection_GetMaxOwnedCopies(_card) {

    if (_card == undefined) return 0;

    if (_card.type == "spirit") return 9999;

    switch (_card.type) {

        case "monster":

        case "weapon":

        case "action":

            return 4;

        default:

            return 4;

    }

}



function collection_GetMaxDeckCopies(_card) {

    return collection_GetMaxOwnedCopies(_card);

}



function collection_GetAllowedAddAmount(_card, _amount) {

    if (_card == undefined || _amount <= 0) return 0;

    var _max = collection_GetMaxOwnedCopies(_card);

    if (_max >= 9999) return _amount;

    var _owned = variable_struct_exists(_card, "owned") ? _card.owned : 0;

    return min(_amount, max(0, _max - _owned));

}



function collection_ClampOwnedOnCard(_card) {

    if (_card == undefined) return;

    var _max = collection_GetMaxOwnedCopies(_card);

    if (_max >= 9999) return;

    if (_card.owned > _max) _card.owned = _max;

}



function collection_GetEffectiveOwned(_card) {

    if (_card == undefined) return 0;



    var _owned = variable_struct_exists(_card, "owned") ? _card.owned : 0;

    return min(_owned, collection_GetMaxDeckCopies(_card));

}



function collection_GetAvailableCopies(_card) {

    if (_card == undefined) return 0;



    var _in_deck = SCR_DBD_GetDeckCount(_card.id);

    return max(0, collection_GetEffectiveOwned(_card) - _in_deck);

}



function collection_GrantFromDatabase() {

    var _granted = 0;



    for (var i = 0; i < array_length(card_DB.cards); i++) {

        var _def = card_DB.cards[i];

        if (!variable_struct_exists(_def, "own")) continue;



        var _amount = floor(real(_def.own));

        if (_amount <= 0) continue;



        var _collection = variable_struct_exists(_def, "collection") ? _def.collection : "";

        AddCardToCollection(_def.id, _amount, _collection);

        _granted++;

    }



    show_debug_message("Granted " + string(_granted) + " starting card types from card pool (JSON own)");

}



/// @desc One-time starting grant from JSON "own". Safe to call from map or deckbuilder.

function collection_EnsurePlayerInitialized() {

    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) {

        SCR_LoadAllCollections();

    }



    if (!variable_global_exists("player_collection") || !is_array(global.player_collection)) {

        global.player_collection = [];

    }



    if (variable_global_exists("player_collection_initialized") && global.player_collection_initialized) {

        return;

    }



    collection_GrantFromDatabase();

    global.player_collection_initialized = true;

}



function collection_ParseIdPoolString(_raw) {

    var _pool = [];

    if (_raw == undefined || string(_raw) == "") return _pool;

    var _parsed = collection_ParseRewardPoolString(_raw);
    return _parsed.ids;

}



/// @desc Parse reward pool string — equal ids "1,2,3" or weighted "8:10,9:90"
function collection_ParseRewardPoolString(_raw) {
    var _parsed = {
        weighted: false,
        ids: [],
        entries: []
    };

    if (_raw == undefined || string(_raw) == "") return _parsed;

    var _parts = string_split(string(_raw), ",");
    for (var i = 0; i < array_length(_parts); i++) {
        var _part = string_trim(_parts[i]);
        if (_part == "") continue;

        if (string_pos(":", _part) > 0) {
            var _colon = string_pos(":", _part);
            var _id_str = string_trim(string_copy(_part, 1, _colon - 1));
            var _wt_str = string_trim(string_copy(_part, _colon + 1, string_length(_part) - _colon));
            var _id = floor(real(_id_str));
            var _weight = real(_wt_str);
            if (_id > 0 && _weight > 0) {
                array_push(_parsed.entries, { id: _id, weight: _weight });
                _parsed.weighted = true;
            }
        } else {
            var _id = floor(real(_part));
            if (_id > 0) array_push(_parsed.ids, _id);
        }
    }

    return _parsed;
}



function collection_PickWeightedIdFromEntries(_entries) {
    if (!is_array(_entries) || array_length(_entries) <= 0) return 0;

    var _total = 0;
    for (var i = 0; i < array_length(_entries); i++) {
        _total += _entries[i].weight;
    }
    if (_total <= 0) return 0;

    var _roll = random(_total);
    var _acc = 0;
    for (var i = 0; i < array_length(_entries); i++) {
        _acc += _entries[i].weight;
        if (_roll < _acc) return _entries[i].id;
    }

    return _entries[array_length(_entries) - 1].id;
}



function collection_PickFromRewardPool(_parsed) {
    if (_parsed == undefined) return 0;

    if (_parsed.weighted && is_array(_parsed.entries) && array_length(_parsed.entries) > 0) {
        return collection_PickWeightedIdFromEntries(_parsed.entries);
    }

    if (is_array(_parsed.ids) && array_length(_parsed.ids) > 0) {
        return collection_PickRandomIdFromPool(_parsed.ids);
    }

    return 0;
}



function collection_PickRandomIdFromPool(_pool) {

    if (!is_array(_pool) || array_length(_pool) <= 0) return 0;

    return _pool[irandom(array_length(_pool) - 1)];

}



function collection_GrantBattleReward(_card_id, _amount = 1, _collection = "") {

    if (_card_id <= 0 || _amount <= 0) return false;



    collection_EnsurePlayerInitialized();

    var _ok = AddCardToCollection(_card_id, _amount, _collection);

    if (_ok) collection_SyncDefinitionsFromDatabase();

    return _ok;

}



function collection_FormatRewardText(_card_id, _amount) {

    if (_card_id <= 0 || _amount <= 0) return "";

    return deck_GetCardName(_card_id) + " x" + string(_amount);

}



function collection_SyncDefinitionsFromDatabase() {

    for (var i = 0; i < array_length(global.player_collection); i++) {

        var _owned = global.player_collection[i].owned;

        var _collection = variable_struct_exists(global.player_collection[i], "collection")

            ? global.player_collection[i].collection : "";

        var _fresh = collection_FindDefinition(global.player_collection[i].id, _collection);

        if (_fresh == undefined) continue;



        global.player_collection[i] = collection_CopyDefinition(_fresh);

        global.player_collection[i].owned = _owned;

        collection_ClampOwnedOnCard(global.player_collection[i]);

    }

}



function SetupPlayerCollection() {

    SCR_LoadAllCollections();

    collection_EnsurePlayerInitialized();

    collection_SyncDefinitionsFromDatabase();



    show_debug_message("=== Player Collection Ready ===");

    show_debug_message("Total card types: " + string(array_length(global.player_collection)));



    for (var i = 0; i < array_length(global.player_collection); i++) {

        show_debug_message("  " + global.player_collection[i].name

            + " | ID:" + string(global.player_collection[i].id)

            + " | Owned:" + string(global.player_collection[i].owned));

    }

}



/// @desc Grant every card from a JSON collection file to the player

function AddAllFromSet(_collection_name, _amount) {

    var _added = 0;

    for (var i = 0; i < array_length(card_DB.cards); i++) {

        var _def = card_DB.cards[i];

        if (!variable_struct_exists(_def, "collection")) continue;

        if (_def.collection != _collection_name) continue;

        AddCardToCollection(_def.id, _amount, _collection_name);

        _added++;

    }

    show_debug_message("Granted " + string(_added) + " card types from " + _collection_name + " x" + string(_amount));

}



/// @desc Permanently remove owned copies (e.g. spirit died in battle). Spirits can reach 0.
function collection_RemoveOwnedCopy(_card_id, _amount = 1, _collection = "") {
    if (_card_id <= 0 || _amount <= 0) return false;

    for (var c = 0; c < array_length(global.player_collection); c++) {
        if (global.player_collection[c].id != _card_id) continue;

        if (_collection != ""
            && variable_struct_exists(global.player_collection[c], "collection")
            && global.player_collection[c].collection != _collection) {
            continue;
        }

        var _before = variable_struct_exists(global.player_collection[c], "owned")
            ? global.player_collection[c].owned : 0;
        global.player_collection[c].owned = max(0, _before - _amount);

        show_debug_message("Lost " + string(min(_amount, _before)) + " copy of "
            + global.player_collection[c].name
            + " (now own " + string(global.player_collection[c].owned) + ")");

        return true;
    }

    return false;
}



function AddCardToCollection(_card_id, _amount, _collection = "") {

    for (var c = 0; c < array_length(global.player_collection); c++) {

        if (global.player_collection[c].id != _card_id) continue;

        if (_collection != ""

            && variable_struct_exists(global.player_collection[c], "collection")

            && global.player_collection[c].collection != _collection) {

            continue;

        }



        var _add = collection_GetAllowedAddAmount(global.player_collection[c], _amount);

        if (_add <= 0) {

            show_debug_message("Collection full for " + global.player_collection[c].name

                + " (max " + string(collection_GetMaxOwnedCopies(global.player_collection[c])) + ")");

            return false;

        }



        global.player_collection[c].owned += _add;

        show_debug_message("Added " + string(_add) + " more to existing: " + global.player_collection[c].name);

        return true;

    }



    var _template = collection_FindDefinition(_card_id, _collection);

    if (_template == undefined) {

        show_debug_message("ERROR: Card ID " + string(_card_id)

            + (_collection != "" ? " in " + _collection : "")

            + " not found in database!");

        return false;

    }



    var _new_card = collection_CopyDefinition(_template);

    var _add_new = collection_GetAllowedAddAmount(_new_card, _amount);

    if (_add_new <= 0) {

        show_debug_message("Collection full for " + _new_card.name

            + " (max " + string(collection_GetMaxOwnedCopies(_new_card)) + ")");

        return false;

    }



    _new_card.owned = _add_new;

    array_push(global.player_collection, _new_card);

    show_debug_message("Added NEW: " + _new_card.name + " x" + string(_add_new));

    return true;

}



function GetPlayerCollection() {

    return global.player_collection;

}



function GetCardOwned(_card_id) {

    for (var i = 0; i < array_length(global.player_collection); i++) {

        if (global.player_collection[i].id == _card_id) {

            return collection_GetEffectiveOwned(global.player_collection[i]);

        }

    }

    return 0;

}



function GetCardAvailable(_card_id) {

    for (var i = 0; i < array_length(global.player_collection); i++) {

        if (global.player_collection[i].id == _card_id) {

            return collection_GetAvailableCopies(global.player_collection[i]);

        }

    }

    return 0;

}



function ClearCollection() {

    global.player_collection = [];

    global.player_collection_initialized = false;

    show_debug_message("Collection cleared!");

}



function DebugPrintCollection() {

    show_debug_message("=== CURRENT COLLECTION ===");

    for (var i = 0; i < array_length(global.player_collection); i++) {

        show_debug_message(string(i) + ". " + global.player_collection[i].name

            + " (ID:" + string(global.player_collection[i].id)

            + ") Owned: " + string(global.player_collection[i].owned)

            + " Available: " + string(GetCardAvailable(global.player_collection[i].id)));

    }

    show_debug_message("Total card types: " + string(array_length(global.player_collection)));

}

