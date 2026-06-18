/// @desc Turn flow + per-turn use tracking

function battle_EndTurn() {
    if (battle_phase != "player") return;

    battle_phase = "enemy";
    show_debug_message("=== Enemy phase (placeholder) ===");

    battle_phase = "player";
    turn_number++;
    battle_ResetTurnUses();

    show_debug_message("=== Player turn " + string(turn_number) + " ===");
}

function battle_ResetTurnUses() {
    battle_CancelTargeting();

    for (var i = 0; i < array_length(weapon_attacks_used); i++) {
        weapon_attacks_used[i] = false;
    }
    battle_RefreshActionUses();
}

function battle_CanUseActionTrait(_trait_index) {
    if (battle_phase != "player") return false;
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
