/// @desc OBJ_MonsterManager Create entry point

function SCR_Monster_Init() {
    battle_won = false;
    monster_queue = [];
    hovered_enemy_slot = -1;
    active_slot_count = 0;
    battle_name = "";

    var _battle_file = "Battle01.json";
    if (variable_global_exists("battle_config_file")) {
        _battle_file = global.battle_config_file;
    }

    var _config = battle_LoadConfig(_battle_file);
    if (_config == undefined) {
        show_debug_message("MonsterManager: battle config failed to load!");
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
        show_debug_message("MonsterManager: BoardManager not found!");
        return;
    }

    monster_ApplyActiveSlotLayout(_board);
    monster_FillActiveSlots(_board);

    show_debug_message("MonsterManager ready | Battle: " + battle_name
        + " | Active slots: " + string(active_slot_count)
        + " | Queue waiting: " + string(array_length(monster_queue)));
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
