/// @desc Enemy database: loading enemy JSON, definitions, runtime monster structs

function monsters_EnsureDatabase() {
    if (!variable_global_exists("monster_DB") || !is_struct(global.monster_DB)) {
        global.monster_DB = { enemies: [] };
    }
}

function load_MonsterSet_ResolvePath(_filename) {
    if (file_exists(_filename)) return _filename;

    var _alts = [
        "enemies/" + _filename,
        "datafiles/enemies/" + _filename,
        "datafiles/test set/" + _filename,
        "datafiles/" + _filename
    ];
    for (var i = 0; i < array_length(_alts); i++) {
        if (file_exists(_alts[i])) return _alts[i];
    }
    return _filename;
}

/// Load an enemy file. Two layouts:
///   { "collections": [ { "collection": ..., "enemy": [...] }, ... ] }   (enemies/animatedcreatures.json)
///   { "collection": ..., "enemy": [...] }                                (one collection per file)
function load_MonsterSet(_filename) {
    monsters_EnsureDatabase();

    var _path = load_MonsterSet_ResolvePath(_filename);
    if (!file_exists(_path)) {
        return;
    }

    var _set = data_ReadJsonFile(_path);
    if (!is_struct(_set)) return;

    if (variable_struct_exists(_set, "collections") && is_array(_set.collections)) {
        for (var c = 0; c < array_length(_set.collections); c++) {
            monster_LoadCollection(_set.collections[c]);
        }
        return;
    }
    monster_LoadCollection(_set);
}

/// Add one { "collection": ..., "enemy": [...] } block to the enemy database
function monster_LoadCollection(_set) {
    if (!is_struct(_set)) return;
    if (!variable_struct_exists(_set, "enemy") || !is_array(_set.enemy)) return;
    if (!variable_struct_exists(_set, "collection") || string(_set.collection) == "") return;

    var _new_enemies = _set.enemy;
    for (var i = 0; i < array_length(_new_enemies); i++) {
        array_push(global.monster_DB.enemies, monster_BuildDefinition(_set.collection, _new_enemies[i]));
    }
}

/// Optional enemy JSON fields, copied as-is when present:
///   animation  scripted draw    icon     hover portrait sprite     arrival  "side" / "drop"
///   hatch      { turns, into }  stances  [profile] swapped each turn   moves  [profile] picked each turn
///   elite      bool
#macro MONSTER_OPTIONAL_FIELDS ["animation", "icon", "arrival", "hatch", "stances", "moves", "elite"]

/// One enemy definition from its JSON entry (shared by every loader)
function monster_BuildDefinition(_collection, _src) {
    var _entry = {
        collection: _collection,
        enemyID: _src.enemyID,
        enemyname: _src.enemyname,
        type: _src.type,
        tag: _src.tag,
        sprite: _src.sprite,
        level: _src.level,
        enemyhealthvalue: _src.enemyhealthvalue,
        enemyattackvalue: _src.enemyattackvalue,
        enemyability: _src.enemyability,
        keywords: keyword_ListFrom(_src)   // "frontline", "tag_in" (scr_card_data)
    };
    var _fields = MONSTER_OPTIONAL_FIELDS;
    for (var i = 0; i < array_length(_fields); i++) {
        if (variable_struct_exists(_src, _fields[i])) variable_struct_set(_entry, _fields[i], variable_struct_get(_src, _fields[i]));
    }
    return _entry;
}

function load_MixedContent(_filename) {
    collection_EnsureDatabase();
    monsters_EnsureDatabase();

    if (!file_exists(_filename)) {
        return;
    }

    var _data = data_ReadJsonFile(_filename);
    var _card_count = 0;
    var _enemy_count = 0;

    if (variable_struct_exists(_data, "cards") && is_array(_data.cards)) {
        for (var i = 0; i < array_length(_data.cards); i++) {
            var _card = card_NormalizeDefinition(_data.cards[i]);
            _card.collection = _data.collection;
            array_push(card_DB.cards, _card);
            _card_count++;
        }
    }

    if (variable_struct_exists(_data, "enemy") && is_array(_data.enemy)) {
        for (var j = 0; j < array_length(_data.enemy); j++) {
            array_push(global.monster_DB.enemies, monster_BuildDefinition(_data.collection, _data.enemy[j]));
            _enemy_count++;
        }
    }

}

function monsters_LoadBuiltinFallback() {
    monsters_EnsureDatabase();

    array_push(global.monster_DB.enemies, {
        collection: "enemyCollection01",
        enemyID: 1,
        enemyname: "Goblin Raider",
        type: "monster",
        tag: ["Goblin", "Set1"],
        sprite: "SPR_Monsterplaceholder",
        animation: "GoblinSoldier",
        level: 1,
        enemyhealthvalue: 6,
        enemyattackvalue: 6,
        enemyability: []
    });

}

function SCR_LoadAllMonsters() {
    monsters_EnsureDatabase();
    global.monster_DB.enemies = [];

    // every example enemy: Grasslands, Forest, Undead, Samurai, Town and the ability testers
    load_MonsterSet("enemies/animatedcreatures.json");
    // more enemy files go in datafiles/enemies/ too: load_MonsterSet("enemies/<file>.json");

    if (array_length(global.monster_DB.enemies) <= 0) {
        monsters_LoadBuiltinFallback();
    }

}

function battle_EnsureMonsterDatabase() {
    monsters_EnsureDatabase();

    if (array_length(global.monster_DB.enemies) <= 0) {
        SCR_LoadAllMonsters();
    }
}

function monster_NormalizeCollectionName(_collection) {
    var _name = string(_collection);
    switch (_name) {
        case "enemySet_01":
        case "enemySet_02":
        case "enemySet_03":
        case "enemyGoblins_01":
        case "enemyOrcs_01":
            return "enemyCollection01";
        default:
            return _name;
    }
}

function monster_GetDefinition(_collection, _enemy_id) {
    monsters_EnsureDatabase();

    _collection = monster_NormalizeCollectionName(_collection);
    _enemy_id = floor(_enemy_id);

    for (var i = 0; i < array_length(global.monster_DB.enemies); i++) {
        var _enemy = global.monster_DB.enemies[i];
        if (_enemy.collection == _collection && floor(_enemy.enemyID) == _enemy_id) {
            return _enemy;
        }
    }

    for (var j = 0; j < array_length(global.monster_DB.enemies); j++) {
        var _fallback = global.monster_DB.enemies[j];
        if (floor(_fallback.enemyID) == _enemy_id) {
            return _fallback;
        }
    }

    return undefined;
}

function monster_CreateInstance(_wave_entry) {
    var _collection = monster_NormalizeCollectionName(_wave_entry.collection);
    var _enemy_id = floor(_wave_entry.enemyID);

    var _def = monster_GetDefinition(_collection, _enemy_id);
    if (_def == undefined) return undefined;

    var _inst = monster_BuildInstance(_def);
    // stance users start in their first stance
    if (monster_HasProfiles(_inst, "stances")) monster_ApplyStance(_inst, 0, false);
    return _inst;
}

function monster_BuildInstance(_def) {
    return {
        id: _def.enemyID,
        collection: _def.collection,
        name: _def.enemyname,
        type: _def.type,
        tag: _def.tag,
        sprite_name: _def.sprite,
        icon_name: struct_GetOr(_def, "icon", ""),
        level: _def.level,
        max_health: _def.enemyhealthvalue,
        health: _def.enemyhealthvalue,
        base_attack: _def.enemyattackvalue,
        attack: _def.enemyattackvalue,
        ability: status_CloneAbilityArray(_def.enemyability),
        alive: true,
        animation: struct_GetOr(_def, "animation", ""),
        elite: struct_GetOr(_def, "elite", false),
        keywords: struct_GetOr(_def, "keywords", []),        // "frontline", "tag_in"
        arrival: struct_GetOr(_def, "arrival", ""),       // "side" / "drop" / "" = random
        hatch: struct_GetOr(_def, "hatch", undefined),    // { turns, into: [{collection, enemyID}] }
        stances: struct_GetOr(_def, "stances", undefined),   // [profile]: one held at a time, swapped each enemy turn
        stance_index: -1,
        stance_name: "",
        moves: struct_GetOr(_def, "moves", undefined),       // [profile]: one picked at the start of each of its turns
        move_index: -1,
        move_name: "",
        anim_attack_fixed: -1,                               // attack animation the current move/stance plays (-1 = random)
        status_effects: [],
        silenced_turns: 0,
        silenced_ability_backup: undefined,
        attack_buff: 0,
        ability_index: 0,
        pending_delayed: undefined,
        attack_all_charges: 0,
        timed_attack_buffs: []
    };
}

function monster_IsElite(_monster) {
    return _monster != undefined && variable_struct_exists(_monster, "elite") && _monster.elite;
}

function SCR_Monster_GetSprite(_monster) {
    return SCR_Monster_ResolveSprite(_monster);
}

function SCR_Monster_GetAbilityText(_monster) {
    if (status_IsSilenced(_monster)) return "none";

    var _traits = trait_GetFromMonster(_monster);
    if (array_length(_traits) <= 0) return "none";
    if (_traits[0].type == "none") return "none";
    return trait_GetDisplayText(_traits[0]);
}
