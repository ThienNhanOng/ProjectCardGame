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
        attack: _def.enemyattackvalue,
        ability: _def.enemyability,
        alive: true
    };
}

function SCR_Monster_GetSprite(_monster) {
    if (variable_struct_exists(_monster, "sprite_name")) {
        var _idx = asset_get_index(_monster.sprite_name);
        if (_idx != -1) return _idx;
    }
    return SPR_Monsterplaceholder;
}

function SCR_Monster_GetAbilityText(_monster) {
    var _traits = trait_GetFromMonster(_monster);
    if (array_length(_traits) <= 0) return "No ability";
    return trait_GetDisplayText(_traits[0]);
}
