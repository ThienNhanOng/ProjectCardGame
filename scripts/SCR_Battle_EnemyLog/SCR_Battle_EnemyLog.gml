/// @desc Append-only enemy turn log (Output window + enemy_battle_log.txt)

function battle_EnemyLog_Init() {
    global.enemy_log_path = working_directory + "enemy_battle_log.txt";
    if (file_exists(global.enemy_log_path)) {
        file_delete(global.enemy_log_path);
    }
    battle_EnemyLog_Write("=== Enemy battle log ===");
    battle_EnemyLog_Write("Log file: " + global.enemy_log_path);
}

function battle_EnemyLog_Write(_line) {
    show_debug_message("[EnemyLog] " + _line);

    if (!variable_global_exists("enemy_log_path")) {
        global.enemy_log_path = working_directory + "enemy_battle_log.txt";
    }

    var _file = file_text_open_append(global.enemy_log_path);
    file_text_write_string(_file, _line + "\r\n");
    file_text_close(_file);
}

function battle_EnemyLog_GetTurn() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return 0;
    with (_bm) return turn_number;
}

function battle_EnemyLog_MonsterLabel(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return "slot " + string(_slot_index);

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined) {
        return "slot " + string(_slot_index);
    }
    return _slot.card.name + " (slot " + string(_slot_index) + ")";
}

function battle_EnemyLog_Attack(_source_slot, _source, _player_slot, _damage) {
    var _turn = battle_EnemyLog_GetTurn();
    var _target = (_player_slot < 0) ? "player" : "player slot " + string(_player_slot);
    var _line = "Turn " + string(_turn)
        + " | " + _source.name + " (slot " + string(_source_slot) + ")"
        + " | ATTACK -> " + _target
        + " for " + string(_damage) + " damage";
    battle_EnemyLog_Write(_line);
}

function battle_EnemyLog_Heal(_source_slot, _source, _target_slot, _amount, _before, _after, _max) {
    var _turn = battle_EnemyLog_GetTurn();
    var _line = "Turn " + string(_turn)
        + " | " + _source.name + " (slot " + string(_source_slot) + ")"
        + " | ABILITY heal +" + string(_amount)
        + " -> " + battle_EnemyLog_MonsterLabel(_target_slot)
        + " HP " + string(_before) + "/" + string(_max)
        + " -> " + string(_after) + "/" + string(_max);
    battle_EnemyLog_Write(_line);
}

function battle_EnemyLog_BuffAttack(_source_slot, _source, _target_slot, _amount, _before, _after) {
    var _turn = battle_EnemyLog_GetTurn();
    var _line = "Turn " + string(_turn)
        + " | " + _source.name + " (slot " + string(_source_slot) + ")"
        + " | ABILITY self_buff +" + string(_amount)
        + " -> " + battle_EnemyLog_MonsterLabel(_target_slot)
        + " ATK " + string(_before) + " -> " + string(_after);
    battle_EnemyLog_Write(_line);
}

function battle_EnemyLog_Skipped(_source_slot, _source, _reason) {
    var _turn = battle_EnemyLog_GetTurn();
    battle_EnemyLog_Write("Turn " + string(_turn)
        + " | " + _source.name + " (slot " + string(_source_slot) + ")"
        + " | SKIPPED | " + _reason);
}
