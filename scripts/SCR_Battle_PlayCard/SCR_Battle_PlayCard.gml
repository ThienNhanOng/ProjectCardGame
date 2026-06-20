/// @desc Card play hooks — abilities come from JSON on the card

function battle_OnMonsterPlayed(_slot_index, _card) {
    battle_EnsureCardHealth(_card);
    battle_CancelTargeting();

    var _traits = trait_GetFromCard(_card);
    for (var i = 0; i < array_length(_traits); i++) {
        var _trait = _traits[i];
        if (_trait.type == "attack") continue;
        if (trait_OnPlayNeedsEnemyTarget(_trait.type) || trait_OnPlayNeedsPlayerTarget(_trait.type)
            || trait_OnPlayNeedsAnyTarget(_trait.type)) continue;
        trait_ExecuteOnPlay(_trait, _slot_index);
    }

    battle_BeginMonsterOnPlayTargeting(_slot_index);
}

function battle_BeginMonsterOnPlayTargeting(_slot_index, _start_trait_index = 0) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined) return;

    var _traits = trait_GetFromCard(_slot.card);
    for (var i = _start_trait_index; i < array_length(_traits); i++) {
        var _type = _traits[i].type;
        if (trait_OnPlayNeedsEnemyTarget(_type)
            || trait_OnPlayNeedsPlayerTarget(_type)
            || trait_OnPlayNeedsAnyTarget(_type)) {
            pending_trait_source = "monster_on_play";
            pending_monster_slot = _slot_index;
            pending_monster_trait_index = i;
            battle_BeginOnPlayTargetMode(_type);
            return;
        }
    }

    battle_CancelTargeting();
}

function battle_MonsterOnPlayContinue(_slot_index, _completed_trait_index) {
    battle_BeginMonsterOnPlayTargeting(_slot_index, _completed_trait_index + 1);
    if (!battle_IsTargeting()) {
        show_debug_message("Monster on-play abilities finished");
    }
}

function battle_ExecuteMonsterOnPlayEnemyTrait(_player_slot, _trait_index, _enemy_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _slot = _board.player_monster_slots[_player_slot];
    if (!_slot.occupied || _slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_slot.card);
    if (_trait_index >= array_length(_traits)) return false;

    var _trait = _traits[_trait_index];
    switch (_trait.type) {
        case "destroy":
            return trait_Execute(_trait, trait_CreateDestroyContext(_trait.amount, "enemy", _enemy_slot));
        case "silence":
            return trait_Execute(_trait, trait_CreateSilenceContext(max(1, _trait.amount), "enemy", _enemy_slot));
    }
    return false;
}

function battle_ExecuteMonsterOnPlayBuffTrait(_player_slot, _trait_index, _side, _target_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _slot = _board.player_monster_slots[_player_slot];
    if (!_slot.occupied || _slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "buff") return false;

    return battle_ExecuteBuffAt(_side, _target_slot, _traits[_trait_index].amount);
}

function battle_ExecuteMonsterOnPlayHealTrait(_player_slot, _trait_index, _target_player_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _slot = _board.player_monster_slots[_player_slot];
    if (!_slot.occupied || _slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "heal") return false;

    var _trait = _traits[_trait_index];
    return trait_Execute(_trait, trait_CreateHealContext(_trait.amount, "player", _target_player_slot));
}

function battle_OnWeaponPlayed(_slot_index, _card) {
    battle_CancelTargeting();
    weapon_EnsureAttackData(_card);

    var _traits = trait_GetFromCard(_card);
    for (var i = 0; i < array_length(_traits); i++) {
        var _trait = _traits[i];
        if (_trait.type == "attack") continue;
        if (trait_OnPlayNeedsEnemyTarget(_trait.type) || trait_OnPlayNeedsPlayerTarget(_trait.type)
            || trait_OnPlayNeedsAnyTarget(_trait.type)) continue;
        trait_ExecuteOnPlay(_trait, _slot_index);
    }

    battle_BeginWeaponOnPlayTargeting(_slot_index);
}

function battle_BeginWeaponOnPlayTargeting(_slot_index, _start_trait_index = 0) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    var _weapon_slot = _board.player_weapon_slots[_slot_index];
    if (!_weapon_slot.occupied || _weapon_slot.card == undefined) return;

    var _traits = trait_GetFromCard(_weapon_slot.card);
    for (var i = _start_trait_index; i < array_length(_traits); i++) {
        var _type = _traits[i].type;
        if (trait_OnPlayNeedsEnemyTarget(_type)
            || trait_OnPlayNeedsPlayerTarget(_type)
            || trait_OnPlayNeedsAnyTarget(_type)) {
            pending_trait_source = "weapon_on_play";
            pending_weapon_slot = _slot_index;
            pending_monster_trait_index = i;
            battle_BeginOnPlayTargetMode(_type);
            return;
        }
    }

    battle_CancelTargeting();
}

function battle_WeaponOnPlayContinue(_slot_index, _completed_trait_index) {
    battle_BeginWeaponOnPlayTargeting(_slot_index, _completed_trait_index + 1);
}

function battle_ExecuteWeaponOnPlayEnemyTrait(_weapon_column, _trait_index, _enemy_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _weapon_slot = _board.player_weapon_slots[_weapon_column];
    if (!_weapon_slot.occupied || _weapon_slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_weapon_slot.card);
    if (_trait_index >= array_length(_traits)) return false;

    var _trait = _traits[_trait_index];
    switch (_trait.type) {
        case "destroy":
            return trait_Execute(_trait, trait_CreateDestroyContext(_trait.amount, "enemy", _enemy_slot));
        case "silence":
            return trait_Execute(_trait, trait_CreateSilenceContext(max(1, _trait.amount), "enemy", _enemy_slot));
    }
    return false;
}

function battle_ExecuteWeaponOnPlayBuffTrait(_weapon_column, _trait_index, _side, _target_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _weapon_slot = _board.player_weapon_slots[_weapon_column];
    if (!_weapon_slot.occupied || _weapon_slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_weapon_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "buff") return false;

    return battle_ExecuteBuffAt(_side, _target_slot, _traits[_trait_index].amount);
}

function battle_ExecuteWeaponOnPlayHealTrait(_weapon_column, _trait_index, _target_player_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _weapon_slot = _board.player_weapon_slots[_weapon_column];
    if (!_weapon_slot.occupied || _weapon_slot.card == undefined) return false;

    var _traits = trait_GetFromCard(_weapon_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "heal") return false;

    var _trait = _traits[_trait_index];
    return trait_Execute(_trait, trait_CreateHealContext(_trait.amount, "player", _target_player_slot));
}

function battle_BeginOnPlayTargetMode(_trait_type) {
    if (trait_OnPlayNeedsAnyTarget(_trait_type)) {
        target_mode = "pick_any_buff";
        return;
    }
    if (trait_OnPlayNeedsPlayerTarget(_trait_type)) {
        battle_BeginPlayerTargetMode(_trait_type);
        return;
    }
    battle_BeginEnemyTargetMode(_trait_type);
}

function battle_BeginPlayerTargetMode(_trait_type) {
    switch (_trait_type) {
        case "heal": target_mode = "pick_player_heal"; break;
        case "self_buff": target_mode = "pick_player_self_buff"; break;
        default: battle_CancelTargeting(); break;
    }
}

function battle_BeginEnemyTargetMode(_trait_type) {
    switch (_trait_type) {
        case "destroy": target_mode = "pick_enemy_destroy"; break;
        case "silence": target_mode = "pick_enemy_silence"; break;
        default: battle_CancelTargeting(); break;
    }
}

function battle_FindFirstTargetingTraitIndex(_traits) {
    for (var i = 0; i < array_length(_traits); i++) {
        if (trait_ActionNeedsTargeting(_traits[i].type)) return i;
    }
    return -1;
}

function battle_BeginActionTargeting(_trait_index, _type) {
    pending_trait_source = "action";
    pending_action_trait_index = _trait_index;
    pending_player_slot = -1;

    switch (_type) {
        case "attack":
            target_mode = "pick_player_monster";
            break;
        case "heal":
            target_mode = "pick_player_heal";
            break;
        case "self_buff":
            target_mode = "pick_player_self_buff";
            break;
        case "buff":
            target_mode = "pick_any_buff";
            break;
        default:
            battle_BeginOnPlayTargetMode(_type);
            break;
    }
}

function battle_ExecuteActionTraitInstant(_trait_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;

    var _trait = _traits[_trait_index];
    var _ok = false;

    switch (_trait.type) {
        case "draw":
        case "draw_cards":
            _ok = trait_ExecuteDraw(trait_CreateDrawContext(max(1, _trait.amount)));
            break;
        case "attack_all":
            _ok = trait_Execute(_trait, trait_CreateAttackAllContext(_trait.amount));
            break;
        case "heal_all":
            _ok = trait_Execute(_trait, trait_CreateHealAllContext(_trait.amount));
            break;
        case "add":
            _ok = trait_Execute(_trait, trait_CreateAddHandContext(_trait.card_id));
            break;
        case "add_deck":
            _ok = trait_Execute(_trait, trait_CreateAddDeckContext(_trait.card_id));
            break;
        case "add_extra_deck":
            _ok = trait_Execute(_trait, trait_CreateAddExtraDeckContext(_trait.card_id));
            break;
    }

    if (_ok) battle_ConsumeActionTrait(_trait_index);
    return _ok;
}

function battle_OnActionCardPlayed(_card) {
    battle_RefreshActionUses();
    battle_CancelTargeting();

    var _traits = trait_GetFromCard(_card);

    for (var a = 0; a < array_length(_traits); a++) {
        if (trait_ActionIsAuto(_traits[a].type)) {
            battle_ExecuteActionTraitInstant(a);
        }
    }

    battle_TargetingContinueAfterAction(-1);
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

    var _traits = trait_GetFromCard(_card);
    for (var i = 0; i < array_length(_traits); i++) {
        var _type = _traits[i].type;
        if (_type == "attack" || _type == "heal" || _type == "self_buff" || _type == "buff") return true;
    }
    return false;
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

function battle_HasAnyBuffTarget() {
    return battle_PickRandomAnyBuffTarget().slot >= 0;
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

function battle_TargetingContinueAfterAction(_last_trait_index) {
    var _traits = battle_GetActionTraits();

    for (var i = _last_trait_index + 1; i < array_length(_traits); i++) {
        if (!battle_CanUseActionTrait(i)) continue;

        if (trait_ActionIsAuto(_traits[i].type)) {
            battle_ExecuteActionTraitInstant(i);
            continue;
        }

        if (!trait_ActionNeedsTargeting(_traits[i].type)) continue;

        var _type = _traits[i].type;
        if ((_type == "attack" || _type == "heal" || _type == "self_buff")
            && !battle_HasPlayerMonsterOnBoard()) {
            show_debug_message("Need a player monster on the board for this action");
            continue;
        }

        if (_type == "buff" && !battle_HasAnyBuffTarget()) {
            show_debug_message("Need a monster on the board to buff");
            continue;
        }

        battle_BeginActionTargeting(i, _type);
        return;
    }

    battle_CancelTargeting();
    battle_ClearActionSlotIfFinished();
}
