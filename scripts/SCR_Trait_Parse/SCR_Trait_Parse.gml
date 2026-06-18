/// @desc Normalize raw JSON ability/action entries into reusable trait structs

function trait_NormalizeEntry(_raw) {
    var _type = "";
    var _amount = 0;
    var _uses = 1;
    var _card_id = -1;
    var _dot_type = "";
    var _duration = 0;

    if (variable_struct_exists(_raw, "type")) {
        _type = string(_raw.type);
    } else if (variable_struct_exists(_raw, "draw_cards")) {
        _type = "draw_cards";
        _amount = _raw.draw_cards;
    } else if (variable_struct_exists(_raw, "draw")) {
        _type = "draw_cards";
        _amount = _raw.draw;
    } else if (variable_struct_exists(_raw, "attackIncrease")) {
        _type = "buff_attack";
        _amount = _raw.attackIncrease;
    } else if (variable_struct_exists(_raw, "destroy_target")) {
        _type = "destroy";
        _amount = 1;
    }

    if (_type == "healing") _type = "heal";
    if (_type == "draw") _type = "draw_cards";
    if (_type == "add_to_hand") _type = "add";

    if (variable_struct_exists(_raw, "amount")) _amount = _raw.amount;
    else if (variable_struct_exists(_raw, "value")) _amount = _raw.value;

    if (variable_struct_exists(_raw, "id")) _card_id = _raw.id;
    else if (variable_struct_exists(_raw, "card_id")) _card_id = _raw.card_id;

    if (variable_struct_exists(_raw, "dot")) _dot_type = string(_raw.dot);
    else if (variable_struct_exists(_raw, "dot_type")) _dot_type = string(_raw.dot_type);

    if (variable_struct_exists(_raw, "duration")) _duration = _raw.duration;

    if (variable_struct_exists(_raw, "uses_per_turn")) _uses = _raw.uses_per_turn;

    return {
        type: _type,
        amount: _amount,
        card_id: _card_id,
        dot_type: _dot_type,
        duration: _duration,
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

function trait_ActionNeedsTargeting(_type) {
    return _type == "attack" || _type == "heal" || _type == "destroy"
        || _type == "silence" || _type == "stasis";
}

function trait_ActionIsAuto(_type) {
    return _type == "draw_cards" || _type == "attack_all" || _type == "heal_all" || _type == "add";
}

function trait_OnPlayNeedsEnemyTarget(_type) {
    return _type == "destroy" || _type == "silence" || _type == "stasis";
}

function trait_GetDisplayText(_trait) {
    if (_trait == undefined) return "None";
    switch (_trait.type) {
        case "attack": return "Attack " + string(_trait.amount);
        case "attack_all": return "Attack all " + string(_trait.amount);
        case "heal": return "Heal " + string(_trait.amount);
        case "heal_all": return "Heal all " + string(_trait.amount);
        case "buff_attack": return "Buff ATK +" + string(_trait.amount);
        case "draw_cards": return "Draw " + string(_trait.amount);
        case "destroy": return "Destroy " + string(_trait.amount);
        case "add": return "Add id " + string(_trait.card_id);
        case "silence": return "Silence " + string(max(1, _trait.amount)) + " turn(s)";
        case "stasis":
            var _dot = (_trait.dot_type != "") ? _trait.dot_type : "?";
            return "Stasis " + _dot;
        default: return string(_trait.type);
    }
}

function trait_ExecuteOnPlay(_trait, _player_slot) {
    if (_trait == undefined) return false;

    switch (_trait.type) {
        case "attack":
            return false;
        case "heal":
            return trait_Execute(_trait, trait_CreateHealContext(_trait.amount, "player", _player_slot));
        case "draw_cards":
            return trait_Execute(_trait, trait_CreateDrawContext(_trait.amount));
        case "attack_all":
            return trait_Execute(_trait, trait_CreateAttackAllContext(_trait.amount));
        case "heal_all":
            return trait_Execute(_trait, trait_CreateHealAllContext(_trait.amount));
        case "add":
            return trait_Execute(_trait, trait_CreateAddHandContext(_trait.card_id));
        case "destroy":
        case "silence":
        case "stasis":
            return false;
        case "buff_attack":
            show_debug_message("On-play buff_attack pending for player monsters");
            return false;
        default:
            show_debug_message("On-play trait pending: " + _trait.type);
            return false;
    }
}
