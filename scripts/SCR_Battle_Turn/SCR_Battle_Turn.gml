/// @desc Turn flow — player draw, end turn, enemy phase

function battle_IsPlayerPhase() {
    return battle_phase == "player";
}

function battle_IsEnemyPhase() {
    return battle_phase == "enemy";
}

function battle_CanEndTurn() {
    if (!battle_IsPlayerPhase()) return false;
    if (battle_IsTargeting()) return false;
    return true;
}

function battle_StartBattle() {
    turn_number = 1;
    battle_phase = "player";
    battle_ResetTurnUses();
    show_debug_message("=== Player turn 1 ===");
}

function battle_BeginNextPlayerTurn() {
    turn_number++;
    battle_phase = "player";
    battle_ResetTurnUses();

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone) {
        status_TickPlayerDoTs(_board);
        status_DecrementPlayerSilence(_board);
    }

    SCR_Hand_DrawFromDeck();
    show_debug_message("=== Player turn " + string(turn_number) + " | Drew 1 card ===");
}

function battle_EndTurn() {
    if (!battle_CanEndTurn()) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.is_dragging) {
        with (_board) SCR_DragDrop_Cancel();
    }

    battle_CancelTargeting();
    battle_phase = "enemy";
    show_debug_message("=== Enemy turn ===");
    battle_RunEnemyTurn();
    battle_BeginNextPlayerTurn();
}

function battle_ResetTurnUses() {
    battle_CancelTargeting();

    for (var i = 0; i < array_length(weapon_attacks_used); i++) {
        weapon_attacks_used[i] = false;
    }
    battle_RefreshActionUses();
}

function battle_CanUseActionTrait(_trait_index) {
    if (!battle_IsPlayerPhase()) return false;
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
