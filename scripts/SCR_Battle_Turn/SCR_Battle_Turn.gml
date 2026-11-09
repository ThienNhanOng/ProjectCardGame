/// @desc Turn flow — player turn, end turn, enemy phase steps, board monster lifespan

/// Non-spirit board monsters are removed after this many player turns on board
#macro BOARD_MONSTER_TURN_LIMIT 3
/// Default extra-deck spirit summons (non-astral) last this many player turns on board
#macro SPIRIT_SUMMON_TURN_LIMIT 1

function battle_IsPlayerPhase() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) return battle_phase == "player";
}

function battle_IsEnemyPhase() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) return battle_phase == "enemy";
}

function battle_CanEndTurn() {
    if (!battle_IsPlayerPhase()) return false;
    if (battle_IsPlayerDefeated()) return false;
    if (battle_IsTargeting()) return false;
    return true;
}

function battle_StartBattle() {
    battlefx_Reset();
    turn_number = 1;
    battle_phase = "player";
    battle_ResetTurnUses();
    battle_RefreshResourcesForTurn();
}

function battle_BeginNextPlayerTurn() {
    turn_number++;
    battle_phase = "player";
    battle_ResetTurnUses();
    battle_RefreshResourcesForTurn();

    status_TickPlayerUnitsAtTurnStart();

    SCR_Hand_DrawFromDeck();
}

function battle_EndTurn() {
    if (!battle_CanEndTurn()) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.is_dragging) {
        with (_board) SCR_DragDrop_Cancel();
    }

    battle_CancelTargeting();
    battle_ClearTurnResourceAddBuffs();
    battle_TickBoardMonsterLifespan();
    battle_phase = "enemy";
    battle_BeginEnemyTurn();
}

function battle_ResetTurnUses() {
    battle_CancelTargeting();

    for (var i = 0; i < array_length(weapon_attacks_used); i++) {
        weapon_attacks_used[i] = 0;
    }
    battle_RefreshActionUses();
    battle_RefreshWeaponRepeatableEffects();
}

function battle_InitBoardMonsterLifespan(_card) {
    if (_card == undefined) return;
    if (card_IsSpiritType(_card)) {
        if (card_IsAstral(_card)) {
            _card.board_expire = false;
            _card.board_turns_left = -1;
        } else {
            _card.board_expire = true;
            _card.board_turns_left = SPIRIT_SUMMON_TURN_LIMIT;
        }
        return;
    }
    _card.board_expire = true;
    _card.board_turns_left = BOARD_MONSTER_TURN_LIMIT;
}

function battle_SetBoardMonsterExpire(_card, _expires) {
    if (_card == undefined) return false;
    if (card_IsSpiritType(_card) && card_IsAstral(_card)) return true;

    _card.board_expire = _expires;
    if (!_expires) {
        _card.board_turns_left = -1;
        return true;
    }

    if (!variable_struct_exists(_card, "board_turns_left") || _card.board_turns_left < 0) {
        _card.board_turns_left = BOARD_MONSTER_TURN_LIMIT;
    }
    return true;
}

function battle_AddBoardMonsterTurns(_card, _amount) {
    if (_card == undefined) return false;
    if (card_IsSpiritType(_card) && card_IsAstral(_card)) return true;
    if (_amount <= 0) return false;

    if (!variable_struct_exists(_card, "board_expire") || !_card.board_expire) return true;
    if (!variable_struct_exists(_card, "board_turns_left") || _card.board_turns_left < 0) {
        _card.board_turns_left = BOARD_MONSTER_TURN_LIMIT;
    }
    _card.board_turns_left += _amount;
    return true;
}

function battle_TickBoardMonsterLifespan() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = array_length(_board.player_monster_slots) - 1; i >= 0; i--) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        if (variable_struct_exists(_slot.card, "board_expire") && !_slot.card.board_expire) continue;

        if (!variable_struct_exists(_slot.card, "board_turns_left")) {
            _slot.card.board_turns_left = card_IsSpiritType(_slot.card)
                ? SPIRIT_SUMMON_TURN_LIMIT
                : BOARD_MONSTER_TURN_LIMIT;
        }
        if (_slot.card.board_turns_left < 0) continue;

        _slot.card.board_turns_left--;
        if (_slot.card.board_turns_left <= 0) {
            combat_RemoveUnit(SIDE_PLAYER, i);
        }
    }
}

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
    status_TickAllTimedAttackBuffs();

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

function battle_EnemyTurn_FindNextSlot(_start_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return -1;

    for (var i = _start_index; i < _mm.active_slot_count; i++) {
        if (unit_Get(SIDE_ENEMY, i) != undefined) return i;
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

    var _monster = unit_Get(SIDE_ENEMY, enemy_turn_slot_index);
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

    // Move on even if the step opened a player choice (discard picker); otherwise the same
    // ability step would run again once the choice closes and the ability would fire twice.
    enemy_turn_step_index++;
    if (enemy_turn_step_index > 4) {
        enemy_turn_step_index = 0;
        enemy_turn_slot_index = battle_EnemyTurn_FindNextSlot(enemy_turn_slot_index + 1);
        if (enemy_turn_slot_index < 0) {
            battle_CompleteEnemyTurn();
            return;
        }
    }

    // a choice is open: monsterAbility_Picker_Finish resumes the turn when the player is done
    if (enemy_turn_picker_pause || monsterAbility_picker_active) return;

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

