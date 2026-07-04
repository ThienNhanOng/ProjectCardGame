/// @desc Attack rules: weapon (1/turn per monster column) + action card traits

function battle_IsSpiritMonster(_card) {
    return (_card != undefined && (_card.type == "spirit" || _card.type == "special_monster"));
}

function battle_GetMonsterStrikeAmount(_card) {
    if (_card == undefined || !battle_IsSpiritMonster(_card)) return 0;
    return battle_GetMonsterBaseStrikeAmount(_card) + card_GetAttackBuff(_card);
}

function battle_GetMonsterBaseStrikeAmount(_card) {
    if (_card == undefined || !battle_IsSpiritMonster(_card)) return 0;

    var _buff = card_GetAttackBuff(_card);
    if (variable_struct_exists(_card, "attack") && real(_card.attack) > _buff) {
        return max(0, floor(real(_card.attack) - _buff));
    }

    var _trait = trait_FindFirst(trait_GetFromCard(_card), "attack");
    if (_trait != undefined && _trait.amount > 0) {
        return max(0, floor(_trait.amount));
    }

    if (variable_struct_exists(_card, "attack") && real(_card.attack) > 0) {
        return max(0, floor(real(_card.attack)));
    }

    return 0;
}

function battle_FindPlayerMonsterColumn(_card) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _card == undefined) return -1;

    with (_board) {
        for (var m = 0; m < array_length(player_monster_slots); m++) {
            var _slot = player_monster_slots[m];
            if (_slot.visible && _slot.occupied && _slot.card == _card) return m;
        }
    }

    return -1;
}

function battle_GetPlayerMonsterSummaryAttack(_card, _column = -1) {
    if (_column < 0) _column = battle_FindPlayerMonsterColumn(_card);
    if (_column >= 0) {
        return battle_ColumnSingleStrikeTotal(battle_GetColumnStrikeParts(_column));
    }
    return card_GetSummaryTotalAttack(_card);
}

function battle_GetColumnStrikeParts(_column) {
    var _parts = {
        monster_strike: 0,
        weapon_strike: 0,
        monster_attack_all: 0,
        weapon_attack_all: 0,
        buff: 0,
        has_weapon: false
    };

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return _parts;
    if (_column < 0 || _column >= array_length(_board.player_monster_slots)) return _parts;

    var _monster_slot = _board.player_monster_slots[_column];
    var _weapon_slot = _board.player_weapon_slots[_column];

    if (_monster_slot.visible && _monster_slot.occupied && _monster_slot.card != undefined) {
        _parts.monster_strike = battle_GetMonsterBaseStrikeAmount(_monster_slot.card);
        _parts.monster_attack_all = battle_GetMonsterAttackAllAmount(_monster_slot.card);
        _parts.buff = card_GetAttackBuff(_monster_slot.card);
    }

    if (_weapon_slot.visible && _weapon_slot.occupied && _weapon_slot.card != undefined) {
        _parts.has_weapon = true;
        _parts.weapon_strike = weapon_GetAttackAmount(_weapon_slot.card);
        _parts.weapon_attack_all = weapon_GetAttackAllAmount(_weapon_slot.card);
    }

    return _parts;
}

function battle_ColumnSingleStrikeTotal(_parts) {
    return _parts.monster_strike + _parts.weapon_strike + _parts.buff;
}

function battle_ColumnWeaponAttackAllTotal(_parts) {
    return _parts.weapon_attack_all + _parts.monster_strike + _parts.buff;
}

function battle_ColumnMonsterAttackAllTotal(_parts) {
    return _parts.monster_attack_all + _parts.weapon_strike + _parts.buff;
}

function weapon_GetAttackAllAmount(_card) {
    if (_card == undefined) return 0;

    var _trait = trait_FindFirst(trait_GetFromCard(_card), "attack_all");
    if (_trait != undefined && _trait.amount > 0) {
        return floor(_trait.amount);
    }
    return 0;
}

function weapon_UsesAttackAll(_card) {
    return weapon_GetAttackAllAmount(_card) > 0;
}

function battle_GetMonsterAttackAllAmount(_card) {
    if (_card == undefined) return 0;

    var _trait = trait_FindFirst(trait_GetFromCard(_card), "attack_all");
    if (_trait != undefined && _trait.amount > 0) {
        return floor(_trait.amount);
    }
    return 0;
}

function battle_MonsterUsesAttackAll(_card) {
    return battle_GetMonsterAttackAllAmount(_card) > 0;
}

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
    return battle_ColumnSingleStrikeTotal(battle_GetColumnStrikeParts(_column));
}

function weapon_EnsureRecursionData(_card) {
    if (_card == undefined || _card.type != "weapon") return;

    if (!variable_struct_exists(_card, "attackRecursion")) {
        _card.attackRecursion = 1;
    } else {
        _card.attackRecursion = max(0, floor(real(_card.attackRecursion)));
    }

    if (!variable_struct_exists(_card, "effectRecursion")) {
        _card.effectRecursion = 1;
    } else {
        _card.effectRecursion = max(1, floor(real(_card.effectRecursion)));
    }
}

function weapon_GetAttackRecursion(_card) {
    if (_card == undefined) return 1;
    weapon_EnsureRecursionData(_card);
    return _card.attackRecursion;
}

function weapon_GetEffectRecursion(_card) {
    if (_card == undefined) return 1;
    weapon_EnsureRecursionData(_card);
    return _card.effectRecursion;
}

function battle_GetColumnAttackRecursion(_column) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 1;
    if (_column < 0 || _column >= array_length(_board.player_weapon_slots)) return 1;

    var _monster_slot = _board.player_monster_slots[_column];
    var _weapon_slot = _board.player_weapon_slots[_column];

    if (_weapon_slot.visible && _weapon_slot.occupied && _weapon_slot.card != undefined) {
        if (_monster_slot.visible && _monster_slot.occupied && _monster_slot.card != undefined
            && battle_IsSpiritMonster(_monster_slot.card)) {
            return 1;
        }
        return weapon_GetAttackRecursion(_weapon_slot.card);
    }
    return 1;
}

function battle_GetColumnAttackUsesLeft(_column) {
    if (_column < 0 || _column >= array_length(weapon_attacks_used)) return 0;
    return max(0, battle_GetColumnAttackRecursion(_column) - weapon_attacks_used[_column]);
}

function battle_ConsumeColumnAttack(_column) {
    if (_column < 0 || _column >= array_length(weapon_attacks_used)) return;
    weapon_attacks_used[_column]++;
}

function weapon_EnsureAttackData(_card) {
    if (_card == undefined || _card.type != "weapon") return;

    weapon_EnsureRecursionData(_card);

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
        if (!variable_struct_exists(_card.ability[j], "repeat")) {
            _card.ability[j].repeat = (_card.attackRecursion > 0);
        }
        if (!variable_struct_exists(_card.ability[j], "recursion")) {
            _card.ability[j].recursion = max(1, _card.attackRecursion);
        }
        _card.ability[j].uses_per_turn = _card.ability[j].repeat ? _card.ability[j].recursion : 0;
        _found = true;
        break;
    }

    if (!_found) {
        array_push(_card.ability, {
            type: "attack",
            amount: _card.attack,
            repeat: (_card.attackRecursion > 0),
            recursion: max(1, _card.attackRecursion),
            uses_per_turn: (_card.attackRecursion > 0) ? max(1, _card.attackRecursion) : 0
        });
    }
}

function battle_CanColumnAttack(_monster_slot_index) {
    if (!battle_IsPlayerPhase()) return false;
    if (_monster_slot_index < 0 || _monster_slot_index >= array_length(weapon_attacks_used)) return false;
    if (battle_GetColumnAttackUsesLeft(_monster_slot_index) <= 0) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _board.is_dragging) return false;

    var _monster_slot = _board.player_monster_slots[_monster_slot_index];
    if (!_monster_slot.visible || !_monster_slot.occupied || _monster_slot.card == undefined) return false;
    if (status_IsShrouded(_monster_slot.card)) return false;

    var _parts = battle_GetColumnStrikeParts(_monster_slot_index);

    if (_parts.weapon_attack_all > 0 || _parts.monster_attack_all > 0) return true;
    if (_parts.monster_strike + _parts.weapon_strike > 0) return true;
    return false;
}

function battle_CanWeaponAttack(_monster_slot_index) {
    return battle_CanColumnAttack(_monster_slot_index);
}

function battle_BeginWeaponAttack(_monster_slot_index) {
    return battle_BeginWeaponAttackStrike(_monster_slot_index);
}

function battle_BeginWeaponAttackStrike(_monster_slot_index) {
    if (battle_IsTargeting()) return false;
    if (!battle_CanColumnAttack(_monster_slot_index)) {
return false;
    }

    var _parts = battle_GetColumnStrikeParts(_monster_slot_index);

    battle_CancelTargeting();

    if (_parts.weapon_attack_all > 0) {
        return battle_ColumnExecuteAttackAll(_monster_slot_index, battle_ColumnWeaponAttackAllTotal(_parts), "weapon");
    }

    if (_parts.monster_attack_all > 0) {
        return battle_ColumnExecuteAttackAll(_monster_slot_index, battle_ColumnMonsterAttackAllTotal(_parts), "spirit");
    }

    if (_parts.monster_strike + _parts.weapon_strike > 0) {
        pending_trait_source = "weapon";
        pending_action_trait_index = -1;
        pending_player_slot = _monster_slot_index;
        target_mode = "pick_enemy";
        return true;
    }

    return false;
}

function battle_GetWeaponColumnAt(_mx, _my) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return -1;

    for (var i = 0; i < array_length(_board.player_weapon_slots); i++) {
        var _weapon_slot = _board.player_weapon_slots[i];
        var _monster_slot = _board.player_monster_slots[i];
        if (!_monster_slot.visible || !_monster_slot.occupied || _monster_slot.card == undefined) continue;
        if (!battle_CanColumnAttack(i)) continue;

        var _over_weapon = false;
        var _over_monster = false;

        if (_weapon_slot.visible && _weapon_slot.occupied && _weapon_slot.card != undefined) {
            if (_mx >= _weapon_slot.x && _mx <= _weapon_slot.x + _weapon_slot.w &&
                _my >= _weapon_slot.y && _my <= _weapon_slot.y + _weapon_slot.h) {
                _over_weapon = true;
            }
        }

        if (_mx >= _monster_slot.x && _mx <= _monster_slot.x + _monster_slot.w &&
            _my >= _monster_slot.y && _my <= _monster_slot.y + _monster_slot.h) {
            _over_monster = true;
        }

        if (_over_weapon || _over_monster) return i;
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

function battle_ColumnExecuteAttackAll(_monster_slot_index, _amount, _source_label) {
    if (!battle_CanColumnAttack(_monster_slot_index)) return false;
    if (_amount <= 0) return false;

    var _ok = trait_AttackAllEnemies(_amount);
    if (_ok) {
        battle_ConsumeColumnAttack(_monster_slot_index);
}
    return _ok;
}

function battle_WeaponAttack(_monster_slot_index, _enemy_slot_index) {
    if (!battle_CanColumnAttack(_monster_slot_index)) {
return false;
    }

    var _parts = battle_GetColumnStrikeParts(_monster_slot_index);
    var _amount = battle_ColumnSingleStrikeTotal(_parts);
    if (_amount <= 0) return false;

    var _ctx = trait_CreateAttackContext(_amount, "enemy", _enemy_slot_index);
    var _ok = trait_ExecuteAttack(_ctx);
    if (_ok) {
        battle_ConsumeColumnAttack(_monster_slot_index);
}
    return _ok;
}

function battle_WeaponAttackAll(_monster_slot_index) {
    var _parts = battle_GetColumnStrikeParts(_monster_slot_index);
    return battle_ColumnExecuteAttackAll(_monster_slot_index,
        battle_ColumnWeaponAttackAllTotal(_parts), "weapon");
}

function battle_MonsterAttackAll(_monster_slot_index) {
    var _parts = battle_GetColumnStrikeParts(_monster_slot_index);
    return battle_ColumnExecuteAttackAll(_monster_slot_index,
        battle_ColumnMonsterAttackAllTotal(_parts), "spirit");
}

function battle_ExecuteActionAttackAll(_trait_index, _player_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) {
return false;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _player_slot = _board.player_monster_slots[_player_slot_index];
    if (!_player_slot.visible || !_player_slot.occupied || _player_slot.card == undefined) {
return false;
    }
    if (status_IsShrouded(_player_slot.card)) {
return false;
    }

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "attack_all") return false;

    var _base_atk = _traits[_trait_index].amount;
    var _buff_atk = card_GetAttackBuff(_player_slot.card);
    var _total_atk = _base_atk + _buff_atk;

    if (!trait_AttackAllEnemies(_total_atk)) return false;

    battle_ConsumeActionTrait(_trait_index);
return true;
}

function battle_ActionAttack(_trait_index, _enemy_slot_index) {
    return battle_ExecuteActionAttack(_trait_index, 0, _enemy_slot_index);
}

function battle_ExecuteActionAttack(_trait_index, _player_slot_index, _enemy_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) {
return false;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _player_slot = _board.player_monster_slots[_player_slot_index];
    if (!_player_slot.visible || !_player_slot.occupied || _player_slot.card == undefined) {
return false;
    }
    if (status_IsShrouded(_player_slot.card)) {
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
return true;
}

function battle_ActionHeal(_trait_index, _player_slot_index) {
    return battle_ExecuteActionHeal(_trait_index, _player_slot_index);
}

function battle_ExecuteActionHeal(_trait_index, _player_slot_index) {
    if (!battle_CanUseActionTrait(_trait_index)) {
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
return false;
    }

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;
    if (_traits[_trait_index].type != "destroy") return false;

    var _ctx = trait_CreateDestroyContext(_traits[_trait_index].amount, "enemy", _enemy_slot_index);
    if (!trait_Execute(_traits[_trait_index], _ctx)) return false;

    battle_ConsumeActionTrait(_trait_index);
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
