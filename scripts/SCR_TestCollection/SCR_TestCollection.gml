// ===== COLLECTION MANAGER =====
// Cards exist in card_DB (JSON). Set "own" on a card to grant copies at init.
// Cards without "own" are obtainable later via rewards/traits.

global.player_collection = [];

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

function collection_GetMaxDeckCopies(_card) {
    if (_card == undefined) return 0;

    switch (_card.type) {
        case "monster":
        case "weapon":
            return 3;
        case "action":
            return 4;
        default:
            return 9999;
    }
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

    show_debug_message("Granted " + string(_granted) + " owned card types from database");
}

function SetupTestCollection() {
    global.player_collection = [];

    collection_GrantFromDatabase();

    show_debug_message("=== Test Collection Ready ===");
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

function AddCardToCollection(_card_id, _amount, _collection = "") {
    for (var c = 0; c < array_length(global.player_collection); c++) {
        if (global.player_collection[c].id != _card_id) continue;
        if (_collection != ""
            && variable_struct_exists(global.player_collection[c], "collection")
            && global.player_collection[c].collection != _collection) {
            continue;
        }

        global.player_collection[c].owned += _amount;
        show_debug_message("Added " + string(_amount) + " more to existing: " + global.player_collection[c].name);
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
    _new_card.owned = _amount;
    array_push(global.player_collection, _new_card);
    show_debug_message("Added NEW: " + _new_card.name + " x" + string(_amount));
    return true;
}

function GetPlayerCollection() {
    return global.player_collection;
}

function GetCardOwned(_card_id) {
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == _card_id) {
            return global.player_collection[i].owned;
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
