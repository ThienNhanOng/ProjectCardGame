/// @desc Read-only monster data helpers (DB lookup, runtime struct, display helpers)

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
            show_debug_message("Monster fallback by ID " + string(_enemy_id)
                + " (wanted collection " + _collection + ")");
            return _fallback;
        }
    }

    show_debug_message("Monster not found: " + _collection + " ID " + string(_enemy_id)
        + " | DB size: " + string(array_length(global.monster_DB.enemies)));
    return undefined;
}

function monster_CreateInstance(_wave_entry) {
    var _collection = monster_NormalizeCollectionName(_wave_entry.collection);
    var _enemy_id = floor(_wave_entry.enemyID);

    var _def = monster_GetDefinition(_collection, _enemy_id);
    if (_def == undefined) return undefined;

    return {
        id: _def.enemyID,
        collection: _def.collection,
        name: _def.enemyname,
        type: _def.type,
        tag: _def.tag,
        sprite_name: _def.sprite,
        level: _def.level,
        max_health: _def.enemyhealthvalue,
        health: _def.enemyhealthvalue,
        base_attack: _def.enemyattackvalue,
        attack: _def.enemyattackvalue,
        ability: status_CloneAbilityArray(_def.enemyability),
        alive: true,
        animation: variable_struct_exists(_def, "animation") ? _def.animation : "",
        elite: variable_struct_exists(_def, "elite") && _def.elite,
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
