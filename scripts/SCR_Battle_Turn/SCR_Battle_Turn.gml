/// @desc Turn flow — player draw, end turn, enemy phase

/// Non-spirit board monsters are removed after this many player turns on board
#macro BOARD_MONSTER_TURN_LIMIT 3

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

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone) {
        status_DecrementPlayerSilence(_board);
    }

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
battle_RunEnemyTurn();
}

function battle_ResetTurnUses() {
    battle_CancelTargeting();

    for (var i = 0; i < array_length(weapon_attacks_used); i++) {
        weapon_attacks_used[i] = 0;
    }
    battle_RefreshActionUses();
    battle_RefreshWeaponRepeatableEffects();
}

function battle_CanUseActionTrait(_trait_index) {
    if (!battle_IsPlayerPhase()) return false;
    if (battle_IsPlayerDefeated()) return false;
    if (_trait_index < 0 || _trait_index >= array_length(action_trait_uses)) return false;
    return action_trait_uses[_trait_index] > 0;
}

function battle_ConsumeActionTrait(_trait_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;
    action_trait_uses[_trait_index]--;
    return true;
}

function battle_GetActionTraits() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || !_board.action_slot.occupied) return [];
    return trait_GetFromCard(_board.action_slot.card);
}

function battle_PickRandomPlayerMonsterSlot() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return -1;

    var _choices = [];
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (_slot.visible && _slot.occupied && _slot.card != undefined) {
            array_push(_choices, i);
        }
    }

    if (array_length(_choices) == 0) return -1;
    return _choices[irandom(array_length(_choices) - 1)];
}

function battle_PlayerMonsterCount() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    var _count = 0;
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (_slot.visible && _slot.occupied && _slot.card != undefined) _count++;
    }
    return _count;
}

function battle_InitBoardMonsterLifespan(_card) {
    if (_card == undefined) return;
    if (battle_IsSpiritMonster(_card)) {
        _card.board_expire = false;
        _card.board_turns_left = -1;
        return;
    }
    _card.board_expire = true;
    _card.board_turns_left = BOARD_MONSTER_TURN_LIMIT;
}

function battle_SetBoardMonsterExpire(_card, _expires) {
    if (_card == undefined) return false;
    if (battle_IsSpiritMonster(_card)) return true;

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
    if (battle_IsSpiritMonster(_card)) return true;
    if (_amount <= 0) return false;

    if (!variable_struct_exists(_card, "board_expire") || !_card.board_expire) return true;
    if (!variable_struct_exists(_card, "board_turns_left") || _card.board_turns_left < 0) {
        _card.board_turns_left = BOARD_MONSTER_TURN_LIMIT;
    }
    _card.board_turns_left += _amount;
    return true;
}

function battle_GetPlayerMonsterCard(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return undefined;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return undefined;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.visible || !_slot.occupied || _slot.card == undefined) return undefined;
    return _slot.card;
}

function trait_ExecuteNoBoardExpire(_trait, _player_slot) {
    var _card = battle_GetPlayerMonsterCard(_player_slot);
    if (_card == undefined) return false;

    battle_SetBoardMonsterExpire(_card, false);
return true;
}

function trait_ExecuteAddBoardTurns(_trait, _player_slot) {
    var _card = battle_GetPlayerMonsterCard(_player_slot);
    if (_card == undefined) return false;

    var _add = max(1, _trait.amount);
    if (!battle_AddBoardMonsterTurns(_card, _add)) return false;

return true;
}

function battle_TickBoardMonsterLifespan() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = array_length(_board.player_monster_slots) - 1; i >= 0; i--) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        if (battle_IsSpiritMonster(_slot.card)) continue;
        if (variable_struct_exists(_slot.card, "board_expire") && !_slot.card.board_expire) continue;

        if (!variable_struct_exists(_slot.card, "board_turns_left")) {
            _slot.card.board_turns_left = BOARD_MONSTER_TURN_LIMIT;
        }
        if (_slot.card.board_turns_left < 0) continue;

        _slot.card.board_turns_left--;
        if (_slot.card.board_turns_left <= 0) {
battle_DestroyPlayerMonster(i);
        }
    }
}

/// Enemies hit board monsters first; overflow from a kill hits the player (spirits never overflow).
function battle_DamagePlayerSide(_amount, _preferred_slot = -1) {
    if (_amount <= 0) return false;

    if (battle_PlayerMonsterCount() <= 0) {
        return battle_DamagePlayer(_amount);
    }

    var _target = _preferred_slot;
    if (_target < 0 || !battle_IsOccupiedPlayerMonsterSlot(_target)) {
        _target = battle_PickRandomPlayerMonsterSlot();
    }
    if (_target < 0) return battle_DamagePlayer(_amount);

    return battle_DamagePlayerMonster(_target, _amount);
}

function battle_IsOccupiedPlayerMonsterSlot(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    return _slot.visible && _slot.occupied && _slot.card != undefined;
}
