/// @desc Backend wave queue (runs on OBJ_MonsterManager instance)

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

function monster_ApplyDamage(_slot_index, _amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;
    if (_slot_index < 0 || _slot_index >= active_slot_count) return;

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) return;

    _slot.card.health = max(0, _slot.card.health - _amount);
if (_slot.card.health <= 0) {
monsterAbility_OnDeath(_slot.card);
        _slot.occupied = false;
        _slot.card = undefined;
        monster_SpawnIntoSlot(_board, _slot_index);
        monster_CheckVictory(_board);
    }
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
