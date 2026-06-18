/// @desc Attack rules: weapon (1/turn per monster column) + action card traits

function battle_CanWeaponAttack(_monster_slot_index) {
    if (battle_phase != "player") return false;
    if (_monster_slot_index < 0 || _monster_slot_index >= array_length(weapon_attacks_used)) return false;
    if (weapon_attacks_used[_monster_slot_index]) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _monster_slot = _board.player_monster_slots[_monster_slot_index];
    var _weapon_slot = _board.player_weapon_slots[_monster_slot_index];

    if (!_monster_slot.visible || !_monster_slot.occupied || _monster_slot.card == undefined) return false;
    if (!_weapon_slot.visible || !_weapon_slot.occupied || _weapon_slot.card == undefined) return false;

    var _attack_trait = trait_FindFirst(trait_GetFromCard(_weapon_slot.card), "attack");
    return _attack_trait != undefined;
}

function battle_WeaponAttack(_monster_slot_index, _enemy_slot_index) {
    if (!battle_CanWeaponAttack(_monster_slot_index)) {
        show_debug_message("Cannot weapon attack from slot " + string(_monster_slot_index));
        return false;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    var _weapon = _board.player_weapon_slots[_monster_slot_index].card;
    var _attack_trait = trait_FindFirst(trait_GetFromCard(_weapon), "attack");
    if (_attack_trait == undefined) return false;

    var _ctx = trait_CreateAttackContext(_attack_trait.amount, "enemy", _enemy_slot_index);
    var _ok = trait_Execute(_attack_trait, _ctx);
    if (_ok) weapon_attacks_used[_monster_slot_index] = true;
    return _ok;
}

function battle_ActionAttack(_trait_index, _enemy_slot_index) {
    return battle_ExecuteActionAttack(_trait_index, 0, _enemy_slot_index);
}

function battle_ExecuteActionAttack(_trait_index, _player_slot_index, _enemy_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) {
        show_debug_message("Action attack unavailable (trait " + string(_trait_index) + ")");
        return false;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _player_slot = _board.player_monster_slots[_player_slot_index];
    if (!_player_slot.visible || !_player_slot.occupied || _player_slot.card == undefined) {
        show_debug_message("Invalid attacking monster slot");
        return false;
    }

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "attack") return false;

    var _ctx = trait_CreateAttackContext(_traits[_trait_index].amount, "enemy", _enemy_slot_index);
    if (!trait_Execute(_traits[_trait_index], _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
    show_debug_message(_player_slot.card.name + " used action attack on enemy slot "
        + string(_enemy_slot_index) + " for " + string(_traits[_trait_index].amount) + " damage");
    return true;
}

function battle_ActionHeal(_trait_index, _player_slot_index) {
    return battle_ExecuteActionHeal(_trait_index, _player_slot_index);
}

function battle_ExecuteActionHeal(_trait_index, _player_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) {
        show_debug_message("Action heal unavailable (trait " + string(_trait_index) + ")");
        return false;
    }

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "heal") return false;

    var _ctx = trait_CreateHealContext(_traits[_trait_index].amount, "player", _player_slot_index);
    if (!trait_Execute(_traits[_trait_index], _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
    return true;
}

function battle_ExecuteActionDestroy(_trait_index, _enemy_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) {
        show_debug_message("Action destroy unavailable (trait " + string(_trait_index) + ")");
        return false;
    }

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "destroy") return false;

    var _ctx = trait_CreateDestroyContext(_traits[_trait_index].amount, "enemy", _enemy_slot_index);
    if (!trait_Execute(_traits[_trait_index], _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
    show_debug_message("Destroyed enemy in slot " + string(_enemy_slot_index));
    return true;
}

function battle_ExecuteActionSilence(_trait_index, _enemy_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "silence") return false;

    var _turns = max(1, _traits[_trait_index].amount);
    var _ctx = trait_CreateSilenceContext(_turns, "enemy", _enemy_slot_index);
    if (!trait_Execute(_traits[_trait_index], _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
    return true;
}

function battle_ExecuteActionStasis(_trait_index, _enemy_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "stasis") return false;

    var _trait = _traits[_trait_index];
    var _ctx = trait_CreateStasisContext(_trait.dot_type, _trait.amount, _trait.duration, "enemy", _enemy_slot_index);
    if (!trait_Execute(_trait, _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
    return true;
}

function battle_MonsterAbilityAttack(_enemy_slot_index, _trait_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _slot = _board.enemy_slots[_enemy_slot_index];
    if (!_slot.occupied || _slot.card == undefined) return false;

    var _traits = trait_GetFromMonster(_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "attack") return false;

    var _ctx = trait_CreateAttackContext(_traits[_trait_index].amount, "player", 0);
    return trait_Execute(_traits[_trait_index], _ctx);
}

function battle_MonsterAbilityHeal(_enemy_slot_index, _trait_index, _target_enemy_slot) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _slot = _board.enemy_slots[_enemy_slot_index];
    if (!_slot.occupied || _slot.card == undefined) return false;

    var _traits = trait_GetFromMonster(_slot.card);
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "heal") return false;

    var _ctx = trait_CreateHealContext(_traits[_trait_index].amount, "enemy", _target_enemy_slot);
    return trait_Execute(_traits[_trait_index], _ctx);
}

function battle_FindActionTraitIndex(_type) {
    var _traits = battle_GetActionTraits();
    for (var i = 0; i < array_length(_traits); i++) {
        if (_traits[i].type == _type) return i;
    }
    return -1;
}
