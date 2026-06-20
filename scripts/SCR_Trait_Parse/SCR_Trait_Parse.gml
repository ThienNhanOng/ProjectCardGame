/// @desc Normalize raw JSON ability/action entries into reusable trait structs



function trait_NormalizeEntry(_raw) {

    var _type = "";

    var _amount = 0;

    var _uses = 1;

    var _card_id = -1;



    if (variable_struct_exists(_raw, "type")) {

        _type = string(_raw.type);

    } else if (variable_struct_exists(_raw, "draw_cards")) {

        _type = "draw_cards";

        _amount = _raw.draw_cards;

    } else if (variable_struct_exists(_raw, "draw")) {

        _type = "draw_cards";

        _amount = _raw.draw;

    } else if (variable_struct_exists(_raw, "attackIncrease")) {

        _type = "self_buff";

        _amount = _raw.attackIncrease;

    } else if (variable_struct_exists(_raw, "destroy_target")) {

        _type = "destroy";

        _amount = 1;

    }



    if (_type == "healing") _type = "heal";

    if (_type == "draw") _type = "draw_cards";

    if (_type == "add_to_hand") _type = "add";

    if (_type == "add_to_deck") _type = "add_deck";

    if (_type == "add_to_extra_deck") _type = "add_extra_deck";

    if (_type == "add_to_hand_tag") _type = "add_hand_tag";
    if (_type == "add_tag") _type = "add_hand_tag";

    if (_type == "buff_attack") _type = "self_buff";



    if (variable_struct_exists(_raw, "amount")) _amount = _raw.amount;

    else if (variable_struct_exists(_raw, "value")) _amount = _raw.value;



    if (variable_struct_exists(_raw, "id")) _card_id = _raw.id;

    else if (variable_struct_exists(_raw, "card_id")) _card_id = _raw.card_id;



    if (_type == "silence") {

        if (variable_struct_exists(_raw, "turns")) _amount = _raw.turns;

        else if (_amount <= 0) _amount = 1;

    }



    var _repeat = false;
    var _recursion = 1;

    if (variable_struct_exists(_raw, "repeat")) {
        _repeat = _raw.repeat;
    }

    if (variable_struct_exists(_raw, "recursion")) {
        _recursion = max(1, floor(real(_raw.recursion)));
    } else if (variable_struct_exists(_raw, "uses_per_turn")) {
        _recursion = max(1, floor(real(_raw.uses_per_turn)));
        _repeat = true;
    }

    if (_repeat) {
        _uses = _recursion;
    } else {
        _uses = 0;
    }

    var _requirements = [];
    var _tags = trait_ParseTags(_raw);
    var _indeck_tags = trait_ParseIndeckTags(_raw);

    if (_type == "conditions" && variable_struct_exists(_raw, "requirements") && is_array(_raw.requirements)) {

        for (var r = 0; r < array_length(_raw.requirements); r++) {

            array_push(_requirements, conditions_NormalizeEntry(_raw.requirements[r]));

        }

    }



    return {
        type: _type,
        amount: _amount,
        card_id: _card_id,
        repeat: _repeat,
        recursion: _recursion,
        uses_per_turn: _uses,
        tags: _tags,
        indeck_tags: _indeck_tags,
        requirements: _requirements
    };
}

function trait_IsRepeatable(_trait) {
    if (_trait == undefined) return false;
    return variable_struct_exists(_trait, "repeat") && _trait.repeat;
}

function trait_GetRecursionLimit(_trait) {
    if (_trait == undefined) return 1;
    if (variable_struct_exists(_trait, "recursion")) {
        return max(1, floor(real(_trait.recursion)));
    }
    if (variable_struct_exists(_trait, "uses_per_turn") && _trait.uses_per_turn > 0) {
        return max(1, floor(real(_trait.uses_per_turn)));
    }
    return 1;
}

function trait_AppendRepeatDisplayText(_text, _trait) {
    if (!trait_IsRepeatable(_trait)) return _text;

    var _limit = trait_GetRecursionLimit(_trait);
    if (_limit <= 1) return _text + "  (once per turn)";
    return _text + "  (" + string(_limit) + "x per turn)";
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



    // Legacy cardSet_02 action cards: "action": "heal", "heal_value": 5

    if (array_length(_traits) == 0

        && _card.type == "action"

        && variable_struct_exists(_card, "action")) {

        var _legacy = { type: string(_card.action), amount: 0, repeat: true, recursion: 1 };

        if (_legacy.type == "heal" && variable_struct_exists(_card, "heal_value")) {

            _legacy.amount = _card.heal_value;

        } else if (_legacy.type == "attack" && variable_struct_exists(_card, "attack_value")) {

            _legacy.amount = _card.attack_value;

        }

        array_push(_traits, trait_NormalizeEntry(_legacy));

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

    return _type == "attack" || _type == "attack_all" || _type == "heal" || _type == "self_buff" || _type == "buff"

        || _type == "destroy" || _type == "silence";

}



function trait_ActionIsAuto(_type) {

    return trait_IsDrawType(_type) || _type == "heal_all"
        || _type == "openzone"
        || _type == "add" || _type == "add_deck" || _type == "add_extra_deck"
        || _type == "add_hand_tag" || _type == "add_deck_tag" || _type == "add_extra_deck_tag";

}



function trait_OnPlayNeedsEnemyTarget(_type) {

    return _type == "destroy" || _type == "silence";

}



function trait_OnPlayNeedsPlayerTarget(_type) {

    return _type == "heal";

}



function trait_OnPlayNeedsAnyTarget(_type) {

    return _type == "buff";

}



function trait_GetDisplayText(_trait) {

    if (_trait == undefined) return "None";

    switch (_trait.type) {

        case "attack": return "Attack " + string(_trait.amount);

        case "attack_all": return "Attack all " + string(_trait.amount);

        case "heal": return "Heal " + string(_trait.amount);

        case "heal_all": return "Heal all " + string(_trait.amount);

        case "self_buff": return "Self buff ATK +" + string(_trait.amount);

        case "buff": return "Buff ATK +" + string(_trait.amount);

        case "draw_cards": return "Draw " + string(_trait.amount);

        case "destroy": return "Destroy " + string(_trait.amount);

        case "add": return "Add to hand id " + string(_trait.card_id);

        case "add_deck": return "Add to deck id " + string(_trait.card_id);

        case "add_extra_deck": return "Add to extra deck id " + string(_trait.card_id);

        case "add_hand_tag":
            if (trait_TraitUsesIndeckTagSearch(_trait)) {
                return "Add to hand (in deck: " + trait_GetTagsDisplayText(_trait.indeck_tags) + ")";
            }
            return "Add to hand (" + trait_GetTagsDisplayText(_trait.tags) + ")";
        case "add_deck_tag":
            if (trait_TraitUsesIndeckTagSearch(_trait)) {
                return "Add to deck (in deck: " + trait_GetTagsDisplayText(_trait.indeck_tags) + ")";
            }
            return "Add to deck (" + trait_GetTagsDisplayText(_trait.tags) + ")";
        case "add_extra_deck_tag":
            if (trait_TraitUsesIndeckTagSearch(_trait)) {
                return "Add to extra deck (in deck: " + trait_GetTagsDisplayText(_trait.indeck_tags) + ")";
            }
            return "Add to extra deck (" + trait_GetTagsDisplayText(_trait.tags) + ")";

        case "openzone":
            var _zones = max(1, _trait.amount);
            if (_zones <= 1) return "Open hidden zone";
            return "Open hidden zones " + string(_zones);

        case "silence": return "Silence 1 target (" + string(max(1, _trait.amount)) + " enemy turn(s))";

        case "conditions": return trait_GetConditionsDisplayText(_trait);

        default: return string(_trait.type);

    }

}



function trait_GetConditionsDisplayText(_trait) {
    if (_trait == undefined) return "Conditions";
    if (!variable_struct_exists(_trait, "requirements") || array_length(_trait.requirements) <= 0) {
        return "Conditions";
    }

    var _txt = "";
    for (var i = 0; i < array_length(_trait.requirements); i++) {
        if (i > 0) _txt += "; ";
        _txt += conditions_GetRequirementText(_trait.requirements[i]);
    }
    return _txt;
}



function trait_ExecuteOnPlay(_trait, _player_slot) {

    if (_trait == undefined) return false;



    switch (_trait.type) {

        case "attack":

        case "heal":

        case "buff":

        case "attack_all":

            return false;

        case "draw":

        case "draw_cards":

            return trait_ExecuteDraw(trait_CreateDrawContext(max(1, _trait.amount)));

        case "heal_all":

            return trait_Execute(_trait, trait_CreateHealAllContext(_trait.amount));

        case "add":

            return trait_Execute(_trait, trait_CreateAddHandContext(_trait.card_id));

        case "add_deck":

            return trait_Execute(_trait, trait_CreateAddDeckContext(_trait.card_id));

        case "add_extra_deck":

            return trait_Execute(_trait, trait_CreateAddExtraDeckContext(_trait.card_id));

        case "add_hand_tag":

            return trait_ExecuteAddHandTag(_trait);

        case "add_deck_tag":

            return trait_ExecuteAddDeckTag(_trait);

        case "add_extra_deck_tag":

            return trait_ExecuteAddExtraDeckTag(_trait);

        case "openzone":

            return trait_ExecuteOpenZone(_trait, _player_slot);

        case "destroy":

        case "silence":

            return false;

        case "self_buff":

            return trait_Execute(_trait, trait_CreateBuffAttackContext(_trait.amount, "player", _player_slot));

        default:

            show_debug_message("On-play trait pending: " + _trait.type);

            return false;

    }

}

