/// @desc Read-only monster data helpers (DB lookup, runtime struct, display helpers)

function monster_GetDefinition(_collection, _enemy_id) {
    for (var i = 0; i < array_length(monster_DB.enemies); i++) {
        var _enemy = monster_DB.enemies[i];
        if (_enemy.collection == _collection && _enemy.enemyID == _enemy_id) {
            return _enemy;
        }
    }

    show_debug_message("Monster not found: " + _collection + " ID " + string(_enemy_id));
    return undefined;
}

function monster_CreateInstance(_wave_entry) {
    var _def = monster_GetDefinition(_wave_entry.collection, _wave_entry.enemyID);
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
        attack_buff: 0
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
