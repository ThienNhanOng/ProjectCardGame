/// @desc Card play hooks — abilities come from JSON on the card

function battle_OnMonsterPlayed(_slot_index, _card) {
    battle_EnsureCardHealth(_card);

    var _traits = trait_GetFromCard(_card);
    for (var i = 0; i < array_length(_traits); i++) {
        var _trait = _traits[i];
        if (_trait.type == "attack") continue;

        switch (_trait.type) {
            case "heal":
                trait_Execute(_trait, trait_CreateHealContext(_trait.amount, "player", _slot_index));
                break;
            default:
                show_debug_message("On-play trait pending: " + _trait.type + " (" + _card.name + ")");
                break;
        }
    }
}

function battle_OnActionCardPlayed(_card) {
    battle_RefreshActionUses();
    battle_CancelTargeting();

    var _attack_idx = battle_FindActionTraitIndex("attack");
    if (_attack_idx >= 0) {
        if (!battle_CanUseActionTrait(_attack_idx)) return;
        if (!battle_HasPlayerMonsterOnBoard()) return;

        pending_trait_source = "action";
        pending_action_trait_index = _attack_idx;
        pending_player_slot = -1;
        target_mode = "pick_player_monster";
        return;
    }

    var _heal_idx = battle_FindActionTraitIndex("heal");
    if (_heal_idx >= 0) {
        if (!battle_CanUseActionTrait(_heal_idx)) return;
        if (!battle_HasPlayerMonsterOnBoard()) return;

        pending_trait_source = "action";
        pending_action_trait_index = _heal_idx;
        pending_player_slot = -1;
        target_mode = "pick_player_heal";
    }
}

function battle_OnWeaponPlayed(_slot_index, _card) {
    var _traits = trait_GetFromCard(_card);
    var _attack = trait_FindFirst(_traits, "attack");

    if (_attack != undefined && battle_CanWeaponAttack(_slot_index)) {
        pending_trait_source = "weapon";
        pending_action_trait_index = -1;
        pending_player_slot = _slot_index;
        target_mode = "pick_enemy";
        return;
    }

    var _heal = trait_FindFirst(_traits, "heal");
    if (_heal != undefined) {
        var _ctx = trait_CreateHealContext(_heal.amount, "player", _slot_index);
        trait_Execute(_heal, _ctx);
    }
}

function battle_HasPlayerMonsterOnBoard() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (_slot.visible && _slot.occupied && _slot.card != undefined) return true;
    }
    return false;
}

function battle_ActionCardRequiresMonster(_card) {
    if (_card == undefined || _card.type != "action") return false;
    return battle_FindActionTraitIndexOnCard(_card, "attack") >= 0
        || battle_FindActionTraitIndexOnCard(_card, "heal") >= 0;
}

function battle_FindActionTraitIndexOnCard(_card, _type) {
    var _traits = trait_GetFromCard(_card);
    for (var i = 0; i < array_length(_traits); i++) {
        if (_traits[i].type == _type) return i;
    }
    return -1;
}

function battle_CanPlayActionCard(_card) {
    if (!battle_ActionCardRequiresMonster(_card)) return true;
    if (battle_HasPlayerMonsterOnBoard()) return true;

    show_debug_message("Need a player monster on the board for this action");
    return false;
}

function battle_IsActionCardFinished() {
    if (array_length(action_trait_uses) == 0) return false;

    for (var i = 0; i < array_length(action_trait_uses); i++) {
        if (action_trait_uses[i] > 0) return false;
    }
    return true;
}

function battle_ClearActionSlotIfFinished() {
    if (!battle_IsActionCardFinished()) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || !_board.action_slot.occupied) return;

    with (_board) {
        SCR_Board_RemoveCard(action_slot);
    }

    action_trait_uses = [];
}

function battle_NotifyCardPlaced(_slot, _card) {
    if (_slot == undefined || _card == undefined) return;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        switch (_slot.type) {
            case "monster":
                battle_OnMonsterPlayed(_slot.index, _card);
                break;
            case "action":
                battle_OnActionCardPlayed(_card);
                break;
            case "weapon":
                battle_OnWeaponPlayed(_slot.index, _card);
                break;
        }
    }
}
