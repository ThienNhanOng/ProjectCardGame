/// @desc Status effects on units (player monsters and enemy monsters alike).
///
/// Generic API — every status goes through these, so adding a new one (poison, burn, regen, ...)
/// means adding one case to each switch below:
///     status_Apply(_unit, "silence", 2);
///     status_Has(_unit, "shroud");
///     status_Tick(_unit, "silence");      // one turn passes
///     status_Remove(_unit, "silence");
///
/// Existing statuses:
///   silence           — unit cannot use abilities (abilities are stored and restored on expiry)
///   shroud            — player monster cannot attack
///   timed_attack_buff — +attack for N turns (status_Apply(_unit, "timed_attack_buff", _turns, { amount, source_name }))

#macro STATUS_SILENCE "silence"
#macro STATUS_SHROUD "shroud"
#macro STATUS_TIMED_ATTACK_BUFF "timed_attack_buff"

// ---------------------------------------------------------------------------
// Generic API
// ---------------------------------------------------------------------------

function status_InitUnit(_unit) {
    if (_unit == undefined) return;
    if (!variable_struct_exists(_unit, "silenced_turns")) _unit.silenced_turns = 0;
    if (!variable_struct_exists(_unit, "shrouded_turns")) _unit.shrouded_turns = 0;
}

function status_InitTimedBuffs(_unit) {
    if (_unit == undefined) return;
    if (!variable_struct_exists(_unit, "timed_attack_buffs") || !is_array(_unit.timed_attack_buffs)) {
        _unit.timed_attack_buffs = [];
    }
}

/// Apply a status for _turns turns. _data carries extra values a status needs.
function status_Apply(_unit, _status, _turns, _data = undefined) {
    if (_unit == undefined) return false;

    switch (_status) {
        case STATUS_SILENCE:
            return status_SilenceUnit(_unit, _turns);
        case STATUS_SHROUD:
            return status_ShroudUnit(_unit, _turns);
        case STATUS_TIMED_ATTACK_BUFF:
            var _amount = (_data != undefined && variable_struct_exists(_data, "amount")) ? _data.amount : 0;
            var _source_name = (_data != undefined && variable_struct_exists(_data, "source_name")) ? _data.source_name : "";
            return status_ApplyTimedAttackBuff(_unit, _amount, _turns, _source_name);
    }
    return false;
}

function status_Has(_unit, _status) {
    if (_unit == undefined) return false;

    switch (_status) {
        case STATUS_SILENCE: return status_IsSilenced(_unit);
        case STATUS_SHROUD: return status_IsShrouded(_unit);
        case STATUS_TIMED_ATTACK_BUFF:
            status_InitTimedBuffs(_unit);
            return array_length(_unit.timed_attack_buffs) > 0;
    }
    return false;
}

/// One turn passes for a status (expired statuses clean themselves up)
function status_Tick(_unit, _status) {
    if (_unit == undefined) return;

    switch (_status) {
        case STATUS_SILENCE: status_TickSilence(_unit); break;
        case STATUS_SHROUD: status_TickShroud(_unit); break;
        case STATUS_TIMED_ATTACK_BUFF: status_TickTimedAttackBuffs(_unit); break;
    }
}

function status_Remove(_unit, _status) {
    if (_unit == undefined) return;

    switch (_status) {
        case STATUS_SILENCE: status_RestoreAbility(_unit); break;
        case STATUS_SHROUD:
            status_InitUnit(_unit);
            _unit.shrouded_turns = 0;
            break;
        case STATUS_TIMED_ATTACK_BUFF:
            status_InitTimedBuffs(_unit);
            for (var i = array_length(_unit.timed_attack_buffs) - 1; i >= 0; i--) {
                card_LoseAttack(_unit, _unit.timed_attack_buffs[i].amount);
            }
            _unit.timed_attack_buffs = [];
            break;
    }
}

/// Status text shown in the hover preview
function status_GetDisplayText(_unit) {
    if (_unit == undefined) return "";
    status_InitUnit(_unit);

    if (_unit.shrouded_turns > 0) {
        return "Shrouded " + string(_unit.shrouded_turns) + " enemy turn(s)";
    }
    if (_unit.silenced_turns > 0) {
        return "Silenced " + string(_unit.silenced_turns) + " enemy turn(s)";
    }
    return "";
}

// ---------------------------------------------------------------------------
// Turn hooks
// ---------------------------------------------------------------------------

/// Start of the player's turn: player monsters' shroud and silence count down
function status_TickPlayerUnitsAtTurnStart() {
    var _slots = unit_GetAliveSlots(SIDE_PLAYER);
    for (var i = 0; i < array_length(_slots); i++) {
        var _unit = unit_Get(SIDE_PLAYER, _slots[i]);
        status_Tick(_unit, STATUS_SHROUD);
        status_Tick(_unit, STATUS_SILENCE);
    }
}

/// End of the enemy phase: timed attack buffs on every unit (both sides) count down
function status_TickAllTimedAttackBuffs() {
    var _sides = [SIDE_ENEMY, SIDE_PLAYER];
    for (var s = 0; s < array_length(_sides); s++) {
        var _slots = unit_GetAliveSlots(_sides[s]);
        for (var i = 0; i < array_length(_slots); i++) {
            status_Tick(unit_Get(_sides[s], _slots[i]), STATUS_TIMED_ATTACK_BUFF);
        }
    }
}

// ---------------------------------------------------------------------------
// Silence — abilities replaced by "none" until it wears off
// ---------------------------------------------------------------------------

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

    // enemy monsters lose any ability that was counting down
    if (variable_struct_exists(_unit, "base_attack")) {
        monsterAbility_ClearPending(_unit);
    }
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

// ---------------------------------------------------------------------------
// Shroud — player monster cannot attack
// ---------------------------------------------------------------------------

function status_IsShrouded(_unit) {
    if (_unit == undefined) return false;
    status_InitUnit(_unit);
    return _unit.shrouded_turns > 0;
}

function status_ShroudUnit(_unit, _turns) {
    if (_unit == undefined) return false;

    _turns = floor(max(1, real(_turns)));
    status_InitUnit(_unit);
    _unit.shrouded_turns = max(_unit.shrouded_turns, _turns);
    return true;
}

function status_TickShroud(_unit) {
    if (_unit == undefined) return;
    status_InitUnit(_unit);
    if (_unit.shrouded_turns <= 0) return;
    _unit.shrouded_turns--;
}

function battle_IsPlayerMonsterSlotShrouded(_slot_index) {
    return status_IsShrouded(unit_Get(SIDE_PLAYER, _slot_index));
}

// ---------------------------------------------------------------------------
// Timed attack buffs — +attack that is removed after N turns
// ---------------------------------------------------------------------------

function status_ApplyTimedAttackBuff(_unit, _amount, _turns, _source_name = "") {
    if (_unit == undefined || _amount <= 0 || _turns <= 0) return false;
    status_InitTimedBuffs(_unit);
    array_push(_unit.timed_attack_buffs, {
        amount: _amount,
        turns_left: _turns,
        source_name: string(_source_name)
    });
    return true;
}

function status_TickTimedAttackBuffs(_unit) {
    status_InitTimedBuffs(_unit);
    if (array_length(_unit.timed_attack_buffs) <= 0) return;

    for (var i = array_length(_unit.timed_attack_buffs) - 1; i >= 0; i--) {
        _unit.timed_attack_buffs[i].turns_left--;
        if (_unit.timed_attack_buffs[i].turns_left <= 0) {
            card_LoseAttack(_unit, _unit.timed_attack_buffs[i].amount);
            array_delete(_unit.timed_attack_buffs, i, 1);
        }
    }
}

// ---------------------------------------------------------------------------
// Battle log lines for statuses
// ---------------------------------------------------------------------------

function battle_StatusLog_Silence(_side, _slot_index, _unit_name, _turns) {
    var _turn = battle_EnemyLog_GetTurn();
    battle_EnemyLog_Write("Turn " + string(_turn)
        + " | SILENCE | " + _unit_name + " (" + _side + " slot " + string(_slot_index) + ")"
        + " | " + string(_turns) + " turn(s)");
}

function battle_StatusLog_Shroud(_slot_index, _unit_name, _turns) {
    var _turn = battle_EnemyLog_GetTurn();
    battle_EnemyLog_Write("Turn " + string(_turn)
        + " | SHROUD | " + _unit_name + " (player slot " + string(_slot_index) + ")"
        + " | " + string(_turns) + " turn(s)");
}
