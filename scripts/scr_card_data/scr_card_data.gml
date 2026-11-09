/// @desc Card database: loading card JSON, card definitions, runtime card copies, type/tag helpers

// ---------------------------------------------------------------------------
// Card type / tag helpers (use these instead of comparing type strings by hand)
// ---------------------------------------------------------------------------

/// Spirit cards live in the extra deck ("spirit", or "special_monster" once summoned)
function card_IsSpiritType(_card) {
    return (_card != undefined && (_card.type == "spirit" || _card.type == "special_monster"));
}

/// Monsters that can stand on the board ("monster" or summoned "special_monster")
function card_IsMonsterType(_card) {
    return (_card != undefined && (_card.type == "monster" || _card.type == "special_monster"));
}

/// Type filter used by costs, discards and conditions — "monster" also matches special_monster
function card_MatchesType(_card, _type) {
    if (_card == undefined) return false;
    if (_type == "monster") return card_IsMonsterType(_card);
    return _card.type == _type;
}

/// True when the card matches any type in the list (an empty list matches everything)
function card_MatchesAnyType(_card, _types) {
    if (_card == undefined) return false;
    if (!is_array(_types) || array_length(_types) <= 0) return true;

    for (var i = 0; i < array_length(_types); i++) {
        if (card_MatchesType(_card, _types[i])) return true;
    }
    return false;
}

/// Case-insensitive: does the card have at least one of the tags?
function card_HasAnyTag(_card, _tags) {
    if (_card == undefined || array_length(_tags) <= 0) return false;
    if (!variable_struct_exists(_card, "tag") || !is_array(_card.tag)) return false;

    for (var t = 0; t < array_length(_tags); t++) {
        var _want = string_lower(string_trim(_tags[t]));
        for (var c = 0; c < array_length(_card.tag); c++) {
            if (string_lower(string(_card.tag[c])) == _want) return true;
        }
    }
    return false;
}

/// Astral spirits persist in the extra deck unless they die on the board.
/// Accepts a card struct, a definition, or a card id.
function card_IsAstral(_card_or_id) {
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

// ---------------------------------------------------------------------------
// Card database
// ---------------------------------------------------------------------------

function collection_EnsureDatabase() {
    if (!variable_global_exists("card_DB") || !is_struct(card_DB)) {
        card_DB = { cards: [] };
    }
}

function load_Collection_ResolvePath(_filename) {
    if (file_exists(_filename)) return _filename;

    var _alts = [
        "datafiles/test set/" + _filename,
        "datafiles/" + _filename
    ];
    for (var i = 0; i < array_length(_alts); i++) {
        if (file_exists(_alts[i])) return _alts[i];
    }
    return _filename;
}

function load_Collection(_filename) {
    collection_EnsureDatabase();

    var _path = load_Collection_ResolvePath(_filename);
    if (!file_exists(_path)) {
        return;
    }

    var _collection = data_ReadJsonFile(_path);
    var _new_cards = _collection.cards;
    for (var i = 0; i < array_length(_new_cards); i++) {
        var _card = card_NormalizeDefinition(_new_cards[i]);
        _card.collection = _collection.collection;
        array_push(card_DB.cards, _card);
    }

}

function SCR_LoadAllCollections() {
    collection_EnsureDatabase();
    card_DB.cards = [];

    load_Collection("Merc_starterdeck01.json");
    load_Collection("AbilityTestCards.json");

}

function deck_GetCardData(card_id) {
    for (var i = 0; i < array_length(card_DB.cards); i++) {
        if (card_DB.cards[i].id == card_id) {
            return card_DB.cards[i];
        }
    }
    return undefined;
}

function deck_GetCardName(card_id) {
    var _card = deck_GetCardData(card_id);
    if (_card != undefined) {
        return _card.name;
    }
    return "Unknown";
}

/// @desc Store immutable base HP from JSON so runtime damage cannot corrupt the DB template
function card_NormalizeDefinition(_raw) {
    if (_raw == undefined) return undefined;

    var _card = {};
    var _keys = variable_struct_get_names(_raw);
    for (var i = 0; i < array_length(_keys); i++) {
        var _key = _keys[i];
        if (_key == "max_health") continue;
        _card[$ _key] = _raw[$ _key];
    }

    var _base_hp = variable_struct_exists(_raw, "health") ? _raw.health : 10;
    _card.base_health = _base_hp;

    if (_card.type == "weapon") {
        weapon_EnsureAttackData(_card);
    }

    card_NormalizeCostsOnCard(_card);

    if ((!variable_struct_exists(_card, "tag") || !is_array(_card.tag) || array_length(_card.tag) <= 0)
        && variable_struct_exists(_raw, "tags") && is_array(_raw.tags)) {
        _card.tag = _raw.tags;
    }

    return _card;
}

function card_GetDefinitionHealth(_template) {
    if (_template == undefined) return 10;
    if (variable_struct_exists(_template, "base_health")) return _template.base_health;
    if (variable_struct_exists(_template, "health")) return _template.health;
    return 10;
}

/// @desc Shallow-copy a DB card so runtime stats (HP, etc.) are per-instance
function card_CreateRuntimeInstance(_template) {
    if (_template == undefined) return undefined;

    var _card = {};
    var _keys = variable_struct_get_names(_template);
    for (var i = 0; i < array_length(_keys); i++) {
        var _key = _keys[i];
        if (_key == "health" || _key == "max_health" || _key == "own") continue;
        _card[$ _key] = _template[$ _key];
    }

    var _base_hp = card_GetDefinitionHealth(_template);
    _card.base_health = _base_hp;
    _card.health = _base_hp;
    _card.max_health = _base_hp;
    _card.status_effects = [];
    _card.silenced_turns = 0;
    _card.shrouded_turns = 0;
    _card.silenced_ability_backup = undefined;
    _card.attack_buff = 0;

    if (_card.type == "weapon") {
        weapon_EnsureAttackData(_card);
    }

    card_NormalizeCostsOnCard(_card);

    return _card;
}

function deck_CreateRuntimeCard(_card_id) {
    var _card = card_CreateRuntimeInstance(deck_GetCardData(_card_id));
    if (_card != undefined) {
        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) trait_ChainApplyDeckIdCosts(_card, _card_id);
        }
    }
    return _card;
}

/// @desc Deck-builder rarity: 0 = common, 1 = cultivated (extend switch for more tiers)
function card_GetRarity(_card) {
    if (_card == undefined) return 0;
    if (!variable_struct_exists(_card, "cardRarity")) return 0;
    return max(0, floor(real(_card.cardRarity)));
}

function card_GetTierLabel(_card) {
    if (_card == undefined) return "";
    if (card_IsSpiritType(_card)) return "";

    switch (card_GetRarity(_card)) {
        case 1: return "cultivated";
        default: return "common";
    }
}

function card_GetTierLabelColor(_card) {
    if (_card == undefined) return c_white;
    if (card_IsSpiritType(_card)) return c_purple;

    switch (card_GetRarity(_card)) {
        case 1: return c_yellow;
        default: return c_ltgray;
    }
}

function battle_EnsureCardHealth(_card) {
    if (_card == undefined) return;

    var _base = card_GetDefinitionHealth(_card);
    if (!variable_struct_exists(_card, "max_health")) {
        _card.max_health = _base;
    }
    if (!variable_struct_exists(_card, "health")) {
        _card.health = _card.max_health;
    }
}
