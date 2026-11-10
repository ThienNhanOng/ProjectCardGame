/// @desc Normalize JSON abilities into trait structs; trait classification and display text

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
    if (_type == "addtohandwithcost") _type = "add_hand_with_cost";
    if (_type == "add_hand_with_cost") _type = "add_hand_with_cost";

    if (_type == "buff_attack") _type = "self_buff";

    if (_type == "summoner") _type = "summon_enemy";
    if (_type == "discard_spirit") _type = "discard_extra_deck";

    var _hand_filter = "";
    if (_type == "discard_monster") { _hand_filter = "monster"; _type = "discard_hand"; }
    if (_type == "discard_action") { _hand_filter = "action"; _type = "discard_hand"; }
    if (_type == "discard_weapon") { _hand_filter = "weapon"; _type = "discard_hand"; }

    if (_type == "increase_counter") _type = "add_counter";
    if (_type == "decrease_counter") _type = "remove_counter";
    if (_type == "no_board_expire" || _type == "disable_board_expire" || _type == "board_persistent") _type = "no_board_expire";
    if (_type == "extend_board_turns" || _type == "board_turns_plus" || _type == "add_board_turn") _type = "add_board_turns";
    if (_type == "board_expire" || _type == "turn_disappear") {
        if (variable_struct_exists(_raw, "value") && !(_raw.value == true || _raw.value == 1)) {
            _type = "no_board_expire";
        }
    }

    if (variable_struct_exists(_raw, "amount")) _amount = _raw.amount;

    else if (variable_struct_exists(_raw, "value")) _amount = _raw.value;

    if (variable_struct_exists(_raw, "id")) _card_id = _raw.id;

    else if (variable_struct_exists(_raw, "card_id")) _card_id = _raw.card_id;

    if (_type == "shrouded") _type = "shroud";

    if (_type == "silence") {

        if (variable_struct_exists(_raw, "turns")) _amount = _raw.turns;

        else if (_amount <= 0) _amount = 1;

    }

    var _repeat = false;
    var _recursion = 1;

    // "repeat" is a GML keyword, so the field is always read/written with [$ "repeat"]
    if (variable_struct_exists(_raw, "repeat")) {
        _repeat = _raw[$ "repeat"];
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
    var _apply_cost = trait_ParseApplyCost(_raw);
    var _delay = 0;
    var _ability_name = "";
    var _buff_turns = 0;
    var _enemy_id = -1;
    var _card_ids = [];
    var _collection = "";
    var _summon_to = "board";

    if (variable_struct_exists(_raw, "delay")) {
        _delay = max(0, floor(_raw.delay));
    }

    if (variable_struct_exists(_raw, "name")) {
        _ability_name = string(_raw.name);
    }

    if (variable_struct_exists(_raw, "card_ids") && is_array(_raw.card_ids)) {
        for (var c = 0; c < array_length(_raw.card_ids); c++) {
            array_push(_card_ids, floor(_raw.card_ids[c]));
        }
    } else if (variable_struct_exists(_raw, "ids") && is_array(_raw.ids)) {
        for (var d = 0; d < array_length(_raw.ids); d++) {
            array_push(_card_ids, floor(_raw.ids[d]));
        }
    }

    if (_type == "summon_enemy") {
        if (variable_struct_exists(_raw, "enemyID")) _enemy_id = floor(_raw.enemyID);
        else if (variable_struct_exists(_raw, "enemy_id")) _enemy_id = floor(_raw.enemy_id);
        else if (variable_struct_exists(_raw, "id")) _enemy_id = floor(_raw.id);
        if (variable_struct_exists(_raw, "collection")) _collection = string(_raw.collection);
        // "to": "board" (default) = into a free spot now, "queue" = the front of the wave queue
        if (variable_struct_exists(_raw, "to") && string_lower(string_trim(string(_raw.to))) == "queue") _summon_to = "queue";
        _card_id = -1;
        if (_delay <= 0 && variable_struct_exists(_raw, "turns")) {
            _delay = max(0, floor(_raw.turns));
        } else if (_delay <= 0 && _amount > 0) {
            _delay = max(0, floor(_amount));
        }
    }

    if (_type == "discard_hand" || _type == "discard_extra_deck" || _type == "add_deck") {
        if (_delay <= 0 && variable_struct_exists(_raw, "turns")) {
            _delay = max(0, floor(_raw.turns));
        }
    }

    if (_type == "self_buff" || _type == "buff") {
        if (variable_struct_exists(_raw, "turns")) {
            _buff_turns = max(1, floor(_raw.turns));
        }
    }

    if (_type == "conditions" && variable_struct_exists(_raw, "requirements") && is_array(_raw.requirements)) {

        for (var r = 0; r < array_length(_raw.requirements); r++) {

            array_push(_requirements, conditions_NormalizeEntry(_raw.requirements[r]));

        }

    }

    // effect + target rule (JSON may override the target with "target")
    var _rule = trait_GetTypeRule(_type);
    var _target = _rule.target;
    if (trait_IsUnitEffect(_rule.effect) && variable_struct_exists(_raw, "target")) {
        var _wanted = trait_NormalizeTargetRule(_raw.target);
        if (_wanted != "") _target = _wanted;
    }
    if (_rule.effect == "attack" && _target != "all_enemies") _target = "single_enemy";
    _type = trait_CanonicalType(_rule.effect, _target, _type);

    var _trait = {
        type: _type,
        effect: _rule.effect,
        target: _target,
        amount: _amount,
        card_id: _card_id,
        recursion: _recursion,
        uses_per_turn: _uses,
        tags: _tags,
        indeck_tags: _indeck_tags,
        apply_cost: _apply_cost,
        requirements: _requirements,
        delay: _delay,
        name: _ability_name,
        buff_turns: _buff_turns,
        enemy_id: _enemy_id,
        card_ids: _card_ids,
        hand_filter: _hand_filter,
        collection: _collection,
        summon_to: _summon_to
    };
    _trait[$ "repeat"] = _repeat;
    return _trait;
}

function trait_IsRepeatable(_trait) {
    if (_trait == undefined) return false;
    return variable_struct_exists(_trait, "repeat") && _trait[$ "repeat"];
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

        var _legacy = { type: string(_card.action), amount: 0, recursion: 1 };
        _legacy[$ "repeat"] = true;

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

/// Preview / log text. Adds the target when JSON changed it from the trait's usual target.
function trait_GetDisplayText(_trait) {
    var _text = trait_GetBaseDisplayText(_trait);
    if (_trait == undefined || !variable_struct_exists(_trait, "target")) return _text;
    if (_trait.effect == "damage" || _trait.effect == "silence" || _trait.effect == "shroud") return _text;
    if (_trait.target == trait_GetTypeRule(_trait.type).target) return _text;
    return _text + " (" + trait_GetTargetLabel(_trait.target) + ")";
}

function trait_GetBaseDisplayText(_trait) {

    if (_trait == undefined) return "None";

    switch (_trait.type) {

        case "attack": return "Attack " + string(_trait.amount);

        case "attack_all": return "Attack all " + string(_trait.amount);

        case "damage": return "Deal " + string(_trait.amount) + " damage to " + trait_GetTargetLabel(_trait.target);

        case "heal": return "Heal " + string(_trait.amount);

        case "heal_all": return "Heal all " + string(_trait.amount);

        case "self_buff": return "Self buff ATK +" + string(_trait.amount);

        case "buff": return "Buff ATK +" + string(_trait.amount);

        case "draw_cards": return "Draw " + string(_trait.amount);

        case "destroy": return "Destroy " + string(_trait.amount);

        case "discard_hand":
            if (_trait.hand_filter != "") return "Discard " + string(max(1, _trait.amount)) + " " + _trait.hand_filter + " card(s)";
            return "Discard " + string(max(1, _trait.amount)) + " hand card(s)";
        case "discard_extra_deck": return "Discard " + string(max(1, _trait.amount)) + " extra deck card(s)";
        case "summon_enemy":
            var _where = (_trait.summon_to == "queue") ? " (to queue)" : "";
            if (_trait.enemy_id >= 0) return "Summon enemy ID " + string(_trait.enemy_id) + _where;
            return "Summon ally" + _where;

        case "summon": return "Summon " + deck_GetCardName(_trait.card_id);

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

        case "add_hand_with_cost":
            var _tag_txt = trait_GetTagsDisplayText(_trait.tags);
            if (array_length(_trait.tags) <= 0) _tag_txt = "any tag";
            var _cost_txt = string(max(0, _trait.apply_cost));
            return "Add to hand (" + _tag_txt + ") with cost " + _cost_txt;

        case "openzone":
            var _zones = max(1, _trait.amount);
            if (_zones <= 1) return "Open hidden zone";
            return "Open hidden zones " + string(_zones);

        case "add_counter":
            return "Add counter +" + string(max(1, _trait.amount)) + " (this turn)";

        case "remove_counter":
            return "Remove counter max -" + string(max(1, _trait.amount)) + " (while alive)";

        case "no_board_expire":
            return "Board expire: off";

        case "add_board_turns":
            return "Board turns +" + string(max(1, _trait.amount));

        case "add_cost":
            var _entry = card_BuildCostEntryFromTrait(_trait);
            if (_entry == undefined) return "Add cost";
            return "Add cost: " + card_FormatCostEntry(_entry);

        case "silence": return "Silence " + trait_GetTargetLabel(_trait.target) + " (" + string(max(1, _trait.amount)) + " enemy turn(s))";
        case "shroud":
            var _shroud_who = (_trait.target == "single_enemy") ? "1 target" : trait_GetTargetLabel(_trait.target);
            return "Shroud " + _shroud_who + " (" + string(max(1, _trait.amount)) + " enemy turn(s))";

        case "discard_action": return "Discard " + string(max(1, _trait.amount)) + " action card(s)";
        case "discard_monster": return "Discard " + string(max(1, _trait.amount)) + " monster card(s)";
        case "discard_weapon": return "Discard " + string(max(1, _trait.amount)) + " weapon card(s)";
        case "discard_spirit": return "Discard " + string(max(1, _trait.amount)) + " spirit card(s)";

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

function trait_ParseTags(_raw) {
    var _tags = [];

    if (variable_struct_exists(_raw, "tags") && is_array(_raw.tags)) {
        for (var i = 0; i < array_length(_raw.tags); i++) {
            array_push(_tags, string(_raw.tags[i]));
        }
    } else if (variable_struct_exists(_raw, "tag")) {
        array_push(_tags, string(_raw.tag));
    }

    return _tags;
}

function trait_ParseIndeckTags(_raw) {
    var _tags = [];

    if (variable_struct_exists(_raw, "indeckTags") && is_array(_raw.indeckTags)) {
        for (var i = 0; i < array_length(_raw.indeckTags); i++) {
            array_push(_tags, string(_raw.indeckTags[i]));
        }
    } else if (variable_struct_exists(_raw, "indeckTag")) {
        if (is_array(_raw.indeckTag)) {
            for (var j = 0; j < array_length(_raw.indeckTag); j++) {
                array_push(_tags, string(_raw.indeckTag[j]));
            }
        } else {
            array_push(_tags, string(_raw.indeckTag));
        }
    }

    return _tags;
}

function trait_TraitUsesIndeckTagSearch(_trait) {
    return (_trait != undefined
        && variable_struct_exists(_trait, "indeck_tags")
        && is_array(_trait.indeck_tags)
        && array_length(_trait.indeck_tags) > 0);
}

function trait_GetTraitSearchTags(_trait) {
    if (trait_TraitUsesIndeckTagSearch(_trait)) return _trait.indeck_tags;
    if (variable_struct_exists(_trait, "tags") && is_array(_trait.tags)) return _trait.tags;
    return [];
}

function trait_GetTagsDisplayText(_tags) {
    if (_tags == undefined || array_length(_tags) <= 0) return "any tag";

    var _txt = "";
    for (var i = 0; i < array_length(_tags); i++) {
        if (i > 0) _txt += ", ";
        _txt += _tags[i];
    }
    return _txt;
}

function trait_ParseApplyCost(_raw) {
    if (_raw == undefined || !variable_struct_exists(_raw, "cost")) return 0;

    var _entry = card_NormalizeCostEntry(_raw.cost);
    if (_entry != undefined) {
        if (card_CostEntryIsTribute(_entry)) return max(0, _entry.amount);
        return max(0, _entry.amount);
    }

    return 0;
}

function trait_GetTagDestinationFromType(_type) {
    switch (_type) {
        case "add_hand_tag":
        case "add_tag":
        case "add_hand_with_cost":
        case "addtohandwithcost": return "hand";
        case "add_deck_tag": return "deck";
        case "add_extra_deck_tag": return "extra_deck";
        default: return "";
    }
}

function trait_GetTagDestinationLabel(_destination) {
    switch (_destination) {
        case "hand": return "hand";
        case "deck": return "deck";
        case "extra_deck": return "extra deck";
        default: return _destination;
    }
}

function trait_IsDrawType(_type) {
    return _type == "draw" || _type == "draw_cards";
}

// ---------------------------------------------------------------------------
// Effects and target rules
//
// Every trait has an EFFECT (what happens) and a TARGET rule (who is affected):
//   self, single_ally, all_allies, single_enemy, all_enemies, single_any, none
// "ally" / "enemy" are relative to the card's owner, so the same JSON works for player cards and enemies.
// The existing trait names keep their usual target; JSON can change it with "target":
//   { "type": "heal", "amount": 3, "target": "all_allies" }      (same as heal_all)
//   { "type": "silence", "amount": 1, "target": "all_enemies" }
// ---------------------------------------------------------------------------

/// Effect and default target of a trait type
function trait_GetTypeRule(_type) {
    switch (_type) {
        case "attack":       return { effect: "attack", target: "single_enemy" };
        case "attack_all":   return { effect: "attack", target: "all_enemies" };
        case "damage":       return { effect: "damage", target: "single_enemy" };
        case "heal":         return { effect: "heal", target: "single_ally" };
        case "heal_all":     return { effect: "heal", target: "all_allies" };
        case "self_buff":    return { effect: "buff", target: "self" };
        case "buff":         return { effect: "buff", target: "single_any" };
        case "destroy":      return { effect: "destroy", target: "single_enemy" };
        case "silence":      return { effect: "silence", target: "single_enemy" };
        case "shroud":       return { effect: "shroud", target: "single_enemy" };

        case "add":
        case "add_deck":
        case "add_extra_deck":
            return { effect: "add_card", target: "none" };

        case "add_hand_tag":
        case "add_deck_tag":
        case "add_extra_deck_tag":
        case "add_hand_with_cost":
            return { effect: "search_card", target: "none" };

        // player cards: put a monster card (by id) onto a free spot you pick
        case "summon":
            return { effect: "summon", target: "free_spot" };

        case "openzone":
        case "add_counter":
        case "remove_counter":
        case "no_board_expire":
        case "add_board_turns":
            return { effect: _type, target: "self" };
    }
    return { effect: _type, target: "none" };
}

/// Effects that act on monsters (units) and therefore use a target rule
function trait_IsUnitEffect(_effect) {
    return _effect == "attack" || _effect == "damage" || _effect == "heal" || _effect == "buff"
        || _effect == "destroy" || _effect == "silence" || _effect == "shroud";
}

/// JSON "target" value -> target rule ("" when unknown)
function trait_NormalizeTargetRule(_raw) {
    switch (string_lower(string_trim(string(_raw)))) {
        case "self": return "self";
        case "ally": case "single_ally": return "single_ally";
        case "allies": case "all_ally": case "all_allies": return "all_allies";
        case "enemy": case "single_enemy": return "single_enemy";
        case "enemies": case "all_enemy": case "all_enemies": return "all_enemies";
        case "any": case "single_any": return "single_any";
    }
    return "";
}

/// Effect + target -> the existing trait name when there is one (heal + all_allies = heal_all),
/// so previews, weapon stacking and enemy AI that look at the type keep working.
function trait_CanonicalType(_effect, _target, _type) {
    switch (_effect) {
        case "attack": return (_target == "all_enemies") ? "attack_all" : "attack";
        case "heal":
            if (_target == "all_allies") return "heal_all";
            return "heal";
        case "buff":
            if (_target == "self") return "self_buff";
            return "buff";
    }
    return _type;
}

function trait_GetTargetLabel(_target) {
    switch (_target) {
        case "self": return "self";
        case "single_ally": return "1 ally";
        case "all_allies": return "all allies";
        case "single_enemy": return "1 enemy";
        case "all_enemies": return "all enemies";
        case "single_any": return "any monster";
    }
    return _target;
}

function trait_GetSinglePick(_target) {
    switch (_target) {
        case "single_enemy": return "enemy";
        case "single_ally": return "ally";
        case "single_any": return "any";
    }
    return "";
}

/// Unit effects that hit everyone matching the rule (or the source itself) with no player pick
function trait_IsAutoUnitEffect(_trait) {
    if (!trait_IsUnitEffect(_trait.effect) || _trait.effect == "attack" || _trait.effect == "shroud") return false;
    return _trait.target == "self" || _trait.target == "all_allies" || _trait.target == "all_enemies";
}

// ---------------------------------------------------------------------------
// What the player has to click (player cards only — enemy targets come from scr_enemy_ai)
// ---------------------------------------------------------------------------

/// On-play trait of a monster / weapon / spirit: "enemy", "ally", "any", "spot" (a free board spot), or "" (no pick).
/// attack / attack_all on a board card are its strike, not an on-play effect; shroud is enemy-only.
function trait_GetOnPlayPick(_trait) {
    if (_trait.effect == "summon") return "spot";
    if (_trait.effect == "attack" || _trait.effect == "shroud") return "";
    if (!trait_IsUnitEffect(_trait.effect)) return "";
    return trait_GetSinglePick(_trait.target);
}

function trait_OnPlayNeedsTarget(_trait) {
    return trait_GetOnPlayPick(_trait) != "";
}

/// Action card trait: "attacker" (choose your attacking monster), "ally", "any", "enemy", "spot", or "".
/// An action card has no board slot, so "self" means a monster you choose.
function trait_GetActionPick(_trait) {
    if (_trait.effect == "summon") return "spot";
    if (_trait.effect == "attack") return "attacker";
    if (_trait.effect == "shroud" || !trait_IsUnitEffect(_trait.effect)) return "";
    if (_trait.target == "self") return "ally";
    return trait_GetSinglePick(_trait.target);
}

function trait_ActionNeedsTargeting(_trait) {
    return trait_GetActionPick(_trait) != "";
}

/// Action traits that run by themselves when the card is played
function trait_ActionIsAuto(_trait) {
    var _type = _trait.type;
    return trait_IsDrawType(_type)
        || _type == "openzone"
        || _type == "add_counter" || _type == "remove_counter"
        || _type == "no_board_expire" || _type == "add_board_turns"
        || _type == "add_hand_with_cost" || _type == "add_cost"
        || _type == "add" || _type == "add_deck" || _type == "add_extra_deck"
        || _type == "add_hand_tag" || _type == "add_deck_tag" || _type == "add_extra_deck_tag"
        || (trait_IsAutoUnitEffect(_trait) && _trait.target != "self");
}

/// Action traits that need one of the player's own monsters on the board
function trait_ActionNeedsOwnMonster(_trait) {
    var _pick = trait_GetActionPick(_trait);
    return _pick == "attacker" || _pick == "ally";
}
