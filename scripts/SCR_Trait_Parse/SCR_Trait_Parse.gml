/// @desc Normalize raw JSON ability/action entries into reusable trait structs

function trait_NormalizeEntry(_raw) {
    var _type = "";
    var _amount = 0;
    var _uses = 1;

    if (variable_struct_exists(_raw, "type")) {
        _type = string(_raw.type);
    } else if (variable_struct_exists(_raw, "draw_cards")) {
        _type = "draw_cards";
        _amount = _raw.draw_cards;
    } else if (variable_struct_exists(_raw, "attackIncrease")) {
        _type = "buff_attack";
        _amount = _raw.attackIncrease;
    }

    if (_type == "healing") _type = "heal";

    if (variable_struct_exists(_raw, "amount")) _amount = _raw.amount;
    else if (variable_struct_exists(_raw, "value")) _amount = _raw.value;

    if (variable_struct_exists(_raw, "uses_per_turn")) _uses = _raw.uses_per_turn;

    return {
        type: _type,
        amount: _amount,
        uses_per_turn: _uses
    };
}

function trait_GetFromCard(_card) {
    var _traits = [];
    if (_card == undefined) return _traits;

    if (variable_struct_exists(_card, "actionType") && is_array(_card.actionType)) {
        for (var i = 0; i < array_length(_card.actionType); i++) {
            array_push(_traits, trait_NormalizeEntry(_card.actionType[i]));
        }
    }

    if (variable_struct_exists(_card, "ability") && is_array(_card.ability)) {
        for (var j = 0; j < array_length(_card.ability); j++) {
            array_push(_traits, trait_NormalizeEntry(_card.ability[j]));
        }
    }

    return _traits;
}

function trait_GetFromMonster(_monster) {
    var _traits = [];
    if (_monster == undefined) return _traits;
    if (!variable_struct_exists(_monster, "ability") || !is_array(_monster.ability)) return _traits;

    for (var i = 0; i < array_length(_monster.ability); i++) {
        array_push(_traits, trait_NormalizeEntry(_monster.ability[i]));
    }
    return _traits;
}

function trait_FindFirst(_traits, _type) {
    for (var i = 0; i < array_length(_traits); i++) {
        if (_traits[i].type == _type) return _traits[i];
    }
    return undefined;
}

function trait_GetDisplayText(_trait) {
    if (_trait == undefined) return "None";
    switch (_trait.type) {
        case "attack": return "Attack " + string(_trait.amount);
        case "heal": return "Heal " + string(_trait.amount);
        case "buff_attack": return "Buff ATK +" + string(_trait.amount);
        case "draw_cards": return "Draw " + string(_trait.amount);
        default: return string(_trait.type);
    }
}
