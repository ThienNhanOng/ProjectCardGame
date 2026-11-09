/// @desc OBJ_MonsterManager — wave queue, spawning, victory check

function SCR_Monster_Init() {
    battle_won = false;
    monster_queue = [];
    hovered_enemy_slot = -1;
    active_slot_count = 0;
    battle_name = "";

    battle_EnsureMonsterDatabase();

    var _config = undefined;

    if (variable_global_exists("battle_runtime_config") && global.battle_runtime_config != undefined) {
        _config = global.battle_runtime_config;
    } else {
        var _battle_file = "Battle01.json";
        if (variable_global_exists("battle_config_file")) {
            _battle_file = global.battle_config_file;
        }
        _config = battle_LoadConfig(_battle_file);
    }

    if (_config == undefined) {
        return;
    }

    battle_name = _config.battle;
    active_slot_count = _config.active_slots;

    battle_EnemyLog_Init();

    for (var i = 0; i < array_length(_config.wave); i++) {
        array_push(monster_queue, _config.wave[i]);
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) {
        return;
    }

    monster_ApplyActiveSlotLayout(_board);
    monster_FillActiveSlots(_board);

    var _living = monster_CountLivingActive(_board);
}

function monster_ApplyActiveSlotLayout(_board) {
    for (var i = 0; i < array_length(_board.enemy_slots); i++) {
        var _slot = _board.enemy_slots[i];
        var _active = (i < active_slot_count);

        _slot.visible = _active;
        if (!_active) {
            _slot.occupied = false;
            _slot.card = undefined;
        }
    }
}

function monster_SpawnIntoSlot(_board, _slot_index) {
    if (_slot_index >= active_slot_count) return false;
    if (array_length(monster_queue) <= 0) return false;

    var _entry = monster_queue[0];
    array_delete(monster_queue, 0, 1);

    var _monster = monster_CreateInstance(_entry);
    if (_monster == undefined) {
        array_insert(monster_queue, 0, _entry);
        return false;
    }

    var _slot = _board.enemy_slots[_slot_index];
    _slot.occupied = true;
    _slot.visible = true;
    _slot.card = _monster;
    battlefx_Arrive(_monster, SIDE_ENEMY, _slot_index, battlefx_SpawnDelay(_slot_index));   // hops in from the right

    return true;
}

function monster_FillActiveSlots(_board) {
    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (_slot.occupied && _slot.card != undefined && _slot.card.alive) continue;
        if (!monster_SpawnIntoSlot(_board, i)) break;
    }

    monster_CheckVictory(_board);
}

function monster_CheckVictory(_board) {
    if (array_length(monster_queue) > 0) {
        battle_won = false;
        return;
    }

    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (_slot.occupied && _slot.card != undefined && _slot.card.alive) {
            battle_won = false;
            return;
        }
    }

    battle_won = true;
    worldmap_NotifyBattleVictory();
}

function monster_GetQueueCount() {
    return array_length(monster_queue);
}

function monster_QueueInsertFront(_entry) {
    if (_entry == undefined) return false;

    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_mm == noone) return false;

    var _board = instance_find(OBJ_BoardManager, 0);

    with (_mm) {
        if (!variable_instance_exists(id, "monster_queue") || !is_array(monster_queue)) {
            monster_queue = [];
        }

        array_insert(monster_queue, 0, _entry);

        if (_board != noone) {
            monster_FillActiveSlots(_board);
        }

    }

    return true;
}

function monster_CountLivingActive(_board) {
    var _count = 0;
    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (_slot.occupied && _slot.card != undefined && _slot.card.alive) {
            _count++;
        }
    }
    return _count;
}
