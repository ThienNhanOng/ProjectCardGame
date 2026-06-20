/// @desc Attack rules: weapon (1/turn per monster column) + action card traits

function weapon_GetAttackAmount(_card) {
    if (_card == undefined) return 0;

    weapon_EnsureAttackData(_card);

    if (variable_struct_exists(_card, "attack") && _card.attack > 0) {
        return floor(_card.attack);
    }

    var _trait = trait_FindFirst(trait_GetFromCard(_card), "attack");
    if (_trait != undefined && _trait.amount > 0) {
        return floor(_trait.amount);
    }

    return 0;
}

function battle_GetColumnWeaponStrikeDamage(_column) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;
    if (_column < 0 || _column >= array_length(_board.player_weapon_slots)) return 0;

    var _weapon_slot = _board.player_weapon_slots[_column];
    var _monster_slot = _board.player_monster_slots[_column];

    var _weapon_atk = 0;
    var _buff_atk = 0;

    if (_weapon_slot.visible && _weapon_slot.occupied && _weapon_slot.card != undefined) {
        _weapon_atk = weapon_GetAttackAmount(_weapon_slot.card);
    }
    if (_monster_slot.visible && _monster_slot.occupied && _monster_slot.card != undefined) {
        _buff_atk = card_GetAttackBuff(_monster_slot.card);
    }

    return _weapon_atk + _buff_atk;
}

function weapon_EnsureAttackData(_card) {
    if (_card == undefined || _card.type != "weapon") return;

    var _atk = 0;
    if (variable_struct_exists(_card, "attack")) _atk = real(_card.attack);

    if (_atk <= 0 && variable_struct_exists(_card, "ability") && is_array(_card.ability)) {
        for (var i = 0; i < array_length(_card.ability); i++) {
            var _entry = _card.ability[i];
            if (!variable_struct_exists(_entry, "type") || _entry.type != "attack") continue;
            if (variable_struct_exists(_entry, "amount")) _atk = real(_entry.amount);
            else if (variable_struct_exists(_entry, "value")) _atk = real(_entry.value);
            break;
        }
    }

    if (_atk <= 0) _atk = 1;
    _card.attack = floor(_atk);

    if (!variable_struct_exists(_card, "ability") || !is_array(_card.ability)) {
        _card.ability = [];
    }

    var _found = false;
    for (var j = 0; j < array_length(_card.ability); j++) {
        if (_card.ability[j].type != "attack") continue;
        _card.ability[j].amount = _card.attack;
        if (!variable_struct_exists(_card.ability[j], "uses_per_turn")) {
            _card.ability[j].uses_per_turn = 1;
        }
        _found = true;
        break;
    }

    if (!_found) {
        array_push(_card.ability, { type: "attack", amount: _card.attack, uses_per_turn: 1 });
    }
}

function battle_CanWeaponAttack(_monster_slot_index) {
    if (battle_phase != "player") return false;
    if (_monster_slot_index < 0 || _monster_slot_index >= array_length(weapon_attacks_used)) return false;
    if (weapon_attacks_used[_monster_slot_index]) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _board.is_dragging) return false;

    var _monster_slot = _board.player_monster_slots[_monster_slot_index];
    var _weapon_slot = _board.player_weapon_slots[_monster_slot_index];

    if (!_monster_slot.visible || !_monster_slot.occupied || _monster_slot.card == undefined) return false;
    if (!_weapon_slot.visible || !_weapon_slot.occupied || _weapon_slot.card == undefined) return false;

    return weapon_GetAttackAmount(_weapon_slot.card) > 0;
}

function battle_BeginWeaponAttack(_monster_slot_index) {
    if (battle_IsTargeting()) return false;
    if (!battle_CanWeaponAttack(_monster_slot_index)) {
        show_debug_message("Weapon attack not available for column " + string(_monster_slot_index));
        return false;
    }

    battle_CancelTargeting();
    pending_trait_source = "weapon";
    pending_action_trait_index = -1;
    pending_player_slot = _monster_slot_index;
    target_mode = "pick_enemy";
    return true;
}

function battle_GetWeaponColumnAt(_mx, _my) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return -1;

    for (var i = 0; i < array_length(_board.player_weapon_slots); i++) {
        var _weapon_slot = _board.player_weapon_slots[i];
        if (!_weapon_slot.visible || !_weapon_slot.occupied || _weapon_slot.card == undefined) continue;
        if (_mx >= _weapon_slot.x && _mx <= _weapon_slot.x + _weapon_slot.w &&
            _my >= _weapon_slot.y && _my <= _weapon_slot.y + _weapon_slot.h) {
            return i;
        }
    }

    for (var j = 0; j < array_length(_board.player_monster_slots); j++) {
        var _monster_slot = _board.player_monster_slots[j];
        var _paired_weapon = _board.player_weapon_slots[j];
        if (!_monster_slot.visible || !_monster_slot.occupied || _monster_slot.card == undefined) continue;
        if (!_paired_weapon.visible || !_paired_weapon.occupied || _paired_weapon.card == undefined) continue;
        if (_mx >= _monster_slot.x && _mx <= _monster_slot.x + _monster_slot.w &&
            _my >= _monster_slot.y && _my <= _monster_slot.y + _monster_slot.h) {
            return j;
        }
    }

    return -1;
}

function SCR_Battle_WeaponInput_Step() {
    if (!battle_IsPlayerPhase() || battle_IsTargeting()) return;
    if (!mouse_check_button_pressed(mb_left)) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _board.is_dragging) return;

    var _column = battle_GetWeaponColumnAt(mouse_x, mouse_y);
    if (_column < 0) return;

    battle_BeginWeaponAttack(_column);
}

function battle_WeaponAttack(_monster_slot_index, _enemy_slot_index) {
    if (!battle_CanWeaponAttack(_monster_slot_index)) {
        show_debug_message("Cannot weapon attack from slot " + string(_monster_slot_index));
        return false;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    var _weapon = _board.player_weapon_slots[_monster_slot_index].card;
    var _monster = _board.player_monster_slots[_monster_slot_index].card;
    var _weapon_atk = weapon_GetAttackAmount(_weapon);
    var _buff_atk = card_GetAttackBuff(_monster);
    var _amount = _weapon_atk + _buff_atk;
    if (_amount <= 0) return false;

    var _ctx = trait_CreateAttackContext(_amount, "enemy", _enemy_slot_index);
    var _ok = trait_ExecuteAttack(_ctx);
    if (_ok) {
        weapon_attacks_used[_monster_slot_index] = true;
        show_debug_message("Weapon attack " + string(_weapon_atk) + "+" + string(_buff_atk)
            + "=" + string(_amount) + " from column " + string(_monster_slot_index)
            + " -> enemy slot " + string(_enemy_slot_index));
    }
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

    var _base_atk = _traits[_trait_index].amount;
    var _buff_atk = card_GetAttackBuff(_player_slot.card);
    var _total_atk = _base_atk + _buff_atk;

    var _ctx = trait_CreateAttackContext(_total_atk, "enemy", _enemy_slot_index);
    if (!trait_Execute(_traits[_trait_index], _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
    show_debug_message(_player_slot.card.name + " used action attack on enemy slot "
        + string(_enemy_slot_index) + " for " + string(_base_atk) + "+" + string(_buff_atk)
        + "=" + string(_total_atk) + " damage");
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

function battle_ExecuteActionSelfBuff(_trait_index, _player_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "self_buff") return false;

    var _ctx = trait_CreateBuffAttackContext(_traits[_trait_index].amount, "player", _player_slot_index);
    if (!trait_Execute(_traits[_trait_index], _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
    return true;
}

function battle_ExecuteActionBuff(_trait_index, _side, _slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "buff") return false;

    if (!battle_ExecuteBuffAt(_side, _slot_index, _traits[_trait_index].amount)) return false;

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
