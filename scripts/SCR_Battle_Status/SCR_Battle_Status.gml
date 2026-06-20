/// @desc Silence runtime state on board units



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

    if (!variable_struct_exists(_unit, "silenced_turns")) _unit.silenced_turns = 0;

}



function status_IsSilenced(_unit) {

    if (_unit == undefined) return false;

    status_InitUnit(_unit);



    if (_unit.silenced_turns > 0) return true;



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

    if (_unit.silenced_turns > 0) {

        return "Silenced " + string(_unit.silenced_turns) + " enemy turn(s)";

    }



    return "";

}



function battle_StatusLog_Silence(_side, _slot_index, _unit_name, _turns) {

    var _turn = battle_EnemyLog_GetTurn();

    battle_EnemyLog_Write("Turn " + string(_turn)

        + " | SILENCE | " + _unit_name + " (" + _side + " slot " + string(_slot_index) + ")"

        + " | " + string(_turns) + " turn(s)");

}

