/// @desc Silence + DoT (stasis) runtime state on board units

function status_CloneAbilityArray(_src) {
    if (_src == undefined || !is_array(_src)) return [];

    var _copy = [];
    for (var i = 0; i < array_length(_src); i++) {
        var _entry = _src[i];
        var _clone = {};
        var _keys = variable_struct_get_names(_entry);
        for (var k = 0; k < array_length(_keys); k++) {
            var _key = _keys[k];
            _clone[$ _key] = _entry[$ _key];
        }
        array_push(_copy, _clone);
    }
    return _copy;
}

function status_InitUnit(_unit) {
    if (_unit == undefined) return;
    if (!variable_struct_exists(_unit, "status_effects")) _unit.status_effects = [];
    if (!variable_struct_exists(_unit, "silenced_turns")) _unit.silenced_turns = 0;
}

function status_IsSilenced(_unit) {
    if (_unit == undefined) return false;
    status_InitUnit(_unit);

    if (_unit.silenced_turns > 0) return true;

    // Ability swapped out for silence even if the counter was lost somehow
    if (variable_struct_exists(_unit, "silenced_ability_backup")
        && _unit.silenced_ability_backup != undefined) {
        return true;
    }

    return false;
}

function status_SilenceUnit(_unit, _turns) {
    if (_unit == undefined) return false;

    _turns = floor(max(1, real(_turns)));
    status_InitUnit(_unit);

    if (_unit.silenced_turns <= 0
        && (!variable_struct_exists(_unit, "silenced_ability_backup")
            || _unit.silenced_ability_backup == undefined)) {
        if (variable_struct_exists(_unit, "ability") && is_array(_unit.ability)) {
            _unit.silenced_ability_backup = status_CloneAbilityArray(_unit.ability);
        } else {
            _unit.silenced_ability_backup = [{ type: "none" }];
        }
    }

    _unit.ability = [{ type: "none" }];
    _unit.silenced_turns = max(_unit.silenced_turns, _turns);
    return true;
}

function status_RestoreAbility(_unit) {
    if (_unit == undefined) return;

    if (variable_struct_exists(_unit, "silenced_ability_backup")
        && _unit.silenced_ability_backup != undefined) {
        _unit.ability = status_CloneAbilityArray(_unit.silenced_ability_backup);
        _unit.silenced_ability_backup = undefined;
    }

    _unit.silenced_turns = 0;
}

function status_TickSilence(_unit) {
    if (_unit == undefined) return;
    status_InitUnit(_unit);
    if (_unit.silenced_turns <= 0) return;

    _unit.silenced_turns--;
    if (_unit.silenced_turns <= 0) {
        status_RestoreAbility(_unit);
    }
}

function status_ApplyDoT(_unit, _dot_type, _damage_override, _duration_override) {
    if (_unit == undefined) return false;

    var _def = dot_GetDefinition(_dot_type);
    if (_def == undefined) return false;

    status_InitUnit(_unit);

    var _damage = (_damage_override > 0) ? _damage_override : _def.damage_per_tick;
    var _duration = (_duration_override > 0) ? _duration_override : _def.default_duration;
    var _label = _def.label;

    for (var i = 0; i < array_length(_unit.status_effects); i++) {
        if (_unit.status_effects[i].dot_type == _dot_type) {
            _unit.status_effects[i].damage = _damage;
            _unit.status_effects[i].ticks = max(_unit.status_effects[i].ticks, _duration);
            _unit.status_effects[i].label = _label;
            return true;
        }
    }

    array_push(_unit.status_effects, {
        dot_type: _dot_type,
        label: _label,
        damage: _damage,
        ticks: _duration
    });
    return true;
}

function status_TickEnemyDoTs(_board, _mm) {
    if (_board == noone || _mm == noone) return;

    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;
        status_TickUnitDoTs(_slot.card, "enemy", i, _slot.card.name);
    }
}

function status_TickPlayerDoTs(_board) {
    if (_board == noone) return;

    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        status_TickUnitDoTs(_slot.card, "player", i, _slot.card.name);
    }
}

function status_TickUnitDoTs(_unit, _side, _slot_index, _unit_name) {
    if (_unit == undefined || !variable_struct_exists(_unit, "status_effects")) return;
    if (array_length(_unit.status_effects) <= 0) return;

    var _mm = instance_find(OBJ_MonsterManager, 0);

    for (var i = array_length(_unit.status_effects) - 1; i >= 0; i--) {
        var _fx = _unit.status_effects[i];
        if (_fx.ticks <= 0) {
            array_delete(_unit.status_effects, i, 1);
            continue;
        }

        if (_side == "enemy" && _mm != noone) {
            with (_mm) {
                monster_ApplyDamage(_slot_index, _fx.damage);
            }
        } else if (_side == "player") {
            battle_DamagePlayerMonster(_slot_index, _fx.damage);
        }

        battle_StatusLog_DoT(_side, _slot_index, _unit_name, _fx.label, _fx.dot_type, _fx.damage, _fx.ticks - 1);

        _fx.ticks--;
        if (_fx.ticks <= 0) {
            array_delete(_unit.status_effects, i, 1);
        }
    }
}

function status_DecrementEnemySilence(_board, _mm) {
    if (_board == noone || _mm == noone) return;

    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.occupied || _slot.card == undefined) continue;
        status_TickSilence(_slot.card);
    }
}

function status_DecrementPlayerSilence(_board) {
    if (_board == noone) return;

    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        status_TickSilence(_slot.card);
    }
}

function status_GetDisplayText(_unit) {
    if (_unit == undefined) return "";

    status_InitUnit(_unit);
    var _parts = [];

    if (_unit.silenced_turns > 0) {
        array_push(_parts, "Silenced " + string(_unit.silenced_turns) + " enemy turn(s)");
    }

    for (var i = 0; i < array_length(_unit.status_effects); i++) {
        var _fx = _unit.status_effects[i];
        array_push(_parts, _fx.label + " " + string(_fx.ticks));
    }

    if (array_length(_parts) <= 0) return "";

    var _text = _parts[0];
    for (var j = 1; j < array_length(_parts); j++) {
        _text += " | " + _parts[j];
    }
    return _text;
}

function battle_StatusLog_DoT(_side, _slot_index, _unit_name, _label, _dot_type, _damage, _ticks_left) {
    var _turn = battle_EnemyLog_GetTurn();
    var _line = "Turn " + string(_turn)
        + " | DoT " + _dot_type + " (" + _label + ")"
        + " | " + _unit_name + " (" + _side + " slot " + string(_slot_index) + ")"
        + " | " + string(_damage) + " damage"
        + " | ticks left " + string(_ticks_left);
    battle_EnemyLog_Write(_line);
}

function battle_StatusLog_Silence(_side, _slot_index, _unit_name, _turns) {
    var _turn = battle_EnemyLog_GetTurn();
    battle_EnemyLog_Write("Turn " + string(_turn)
        + " | SILENCE | " + _unit_name + " (" + _side + " slot " + string(_slot_index) + ")"
        + " | " + string(_turns) + " turn(s)");
}

function battle_StatusLog_Stasis(_side, _slot_index, _unit_name, _dot_type, _damage, _duration) {
    var _turn = battle_EnemyLog_GetTurn();
    var _def = dot_GetDefinition(_dot_type);
    var _label = (_def != undefined) ? _def.label : _dot_type;
    battle_EnemyLog_Write("Turn " + string(_turn)
        + " | STASIS " + _dot_type + " (" + _label + ")"
        + " | " + _unit_name + " (" + _side + " slot " + string(_slot_index) + ")"
        + " | " + string(_damage) + " per tick x " + string(_duration));
}
