/// @desc Enemy turn — sequential steps with delays; every enemy attacks each turn

#macro ENEMY_TURN_STEP_DELAY room_speed

function battle_EnemyTurn_Init() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;
    with (_bm) {
        enemy_turn_active = false;
        enemy_turn_waiting = false;
        enemy_turn_timer = 0;
        enemy_turn_slot_index = 0;
        enemy_turn_step_index = 0;
        monsterAbility_Picker_Init();
    }
}

function battle_EnemyTurn_IsActive() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) return enemy_turn_active;
}

function battle_BeginEnemyTurn() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) {
        battle_CompleteEnemyTurn();
        return;
    }

    with (_bm) {
        enemy_turn_active = true;
        enemy_turn_waiting = false;
        enemy_turn_timer = 0;
        enemy_turn_slot_index = -1;
        enemy_turn_step_index = 0;
    }

    battle_EnemyLog_Write("--- Enemy phase ---");
    battle_EnemyTurn_QueueDelay();
}

function battle_CompleteEnemyTurn() {
    monsterAbility_TickAllTimedBuffs();

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) {
            enemy_turn_active = false;
            enemy_turn_waiting = false;
            enemy_turn_timer = 0;
        }
    }

    if (!battle_IsPlayerDefeated()) {
        battle_BeginNextPlayerTurn();
    }
}

function battle_EnemyTurn_QueueDelay() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;
    with (_bm) {
        enemy_turn_waiting = true;
        enemy_turn_timer = ENEMY_TURN_STEP_DELAY;
    }
}

function battle_EnemyTurn_GetLiveMonster(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return undefined;
    if (_slot_index < 0 || _slot_index >= array_length(_board.enemy_slots)) return undefined;

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.visible || !_slot.occupied || _slot.card == undefined || !_slot.card.alive) {
        return undefined;
    }
    return _slot.card;
}

function battle_EnemyTurn_FindNextSlot(_start_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return -1;

    for (var i = _start_index; i < _mm.active_slot_count; i++) {
        if (battle_EnemyTurn_GetLiveMonster(i) != undefined) return i;
    }
    return -1;
}

function battle_EnemyTurn_RunCurrentStep(_slot_index, _monster) {
    switch (enemy_turn_step_index) {
        case 0:
            monsterAbility_InitState(_monster);
            if (!status_IsSilenced(_monster)) {
                monsterAbility_LogCountdown(_slot_index, _monster);
            }
            break;

        case 1:
            if (!status_IsSilenced(_monster)) {
                monsterAbility_TryActivateStep(_slot_index, _monster);
            }
            break;

        case 2:
            monsterAbility_PerformAttack(_slot_index, _monster);
            break;

        case 3:
            battle_EnemyLog_Action(_monster.name + " ended its turn.");
            break;

        case 4:
            if (!status_IsSilenced(_monster)) {
                monsterAbility_TickDelayedCountdown(_monster);
                monsterAbility_AdvanceCycle(_monster);
            }
            status_TickSilence(_monster);
            break;
    }
}

function battle_EnemyTurn_AdvanceStep() {
    if (battle_IsPlayerDefeated()) {
        battle_CompleteEnemyTurn();
        return;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) {
        battle_CompleteEnemyTurn();
        return;
    }

    if (enemy_turn_slot_index < 0) {
        enemy_turn_slot_index = battle_EnemyTurn_FindNextSlot(0);
        if (enemy_turn_slot_index < 0) {
            battle_CompleteEnemyTurn();
            return;
        }
        enemy_turn_step_index = 0;
    }

    var _monster = battle_EnemyTurn_GetLiveMonster(enemy_turn_slot_index);
    if (_monster == undefined) {
        enemy_turn_slot_index = battle_EnemyTurn_FindNextSlot(enemy_turn_slot_index + 1);
        enemy_turn_step_index = 0;
        if (enemy_turn_slot_index < 0) {
            battle_CompleteEnemyTurn();
            return;
        }
        battle_EnemyTurn_QueueDelay();
        return;
    }

    battle_EnemyTurn_RunCurrentStep(enemy_turn_slot_index, _monster);

    if (enemy_turn_picker_pause || monsterAbility_picker_active) {
        return;
    }

    enemy_turn_step_index++;
    if (enemy_turn_step_index > 4) {
        enemy_turn_step_index = 0;
        enemy_turn_slot_index = battle_EnemyTurn_FindNextSlot(enemy_turn_slot_index + 1);
        if (enemy_turn_slot_index < 0) {
            battle_CompleteEnemyTurn();
            return;
        }
    }

    battle_EnemyTurn_QueueDelay();
}

function battle_EnemyTurn_Step() {
    if (!battle_IsEnemyPhase()) return;
    if (!battle_EnemyTurn_IsActive()) return;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        if (enemy_turn_picker_pause || monsterAbility_picker_active) {
            return;
        }
        if (enemy_turn_waiting) {
            enemy_turn_timer--;
            if (enemy_turn_timer > 0) return;
            enemy_turn_waiting = false;
        }
        battle_EnemyTurn_AdvanceStep();
    }
}

function battle_RunEnemyTurn() {
    battle_BeginEnemyTurn();
}
