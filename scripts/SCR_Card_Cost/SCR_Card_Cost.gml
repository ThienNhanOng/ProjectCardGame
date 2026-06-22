/// @desc Card cost parsing and payment — cost(amount), cost(tag, amount), cost(id, amount)

function card_NormalizeCostEntry(_raw) {
    if (_raw == undefined) return undefined;

    if (is_real(_raw) || is_int64(_raw) || is_bool(_raw)) {
        var _num = floor(real(_raw));
        if (_num == 0) return undefined;
        return { amount: _num };
    }

    if (!is_struct(_raw)) return undefined;

    var _amount = 0;
    if (variable_struct_exists(_raw, "amount")) {
        _amount = floor(real(_raw.amount));
    } else if (variable_struct_exists(_raw, "value")) {
        _amount = floor(real(_raw.value));
    }

    var _entry = { amount: _amount };

    if (variable_struct_exists(_raw, "tag")) {
        _entry.tag = string(_raw.tag);
    } else if (variable_struct_exists(_raw, "tags") && is_array(_raw.tags) && array_length(_raw.tags) > 0) {
        _entry.tag = string(_raw.tags[0]);
    }

    if (variable_struct_exists(_raw, "id")) {
        _entry.id = floor(real(_raw.id));
    } else if (variable_struct_exists(_raw, "card_id")) {
        _entry.id = floor(real(_raw.card_id));
    }

    if (variable_struct_exists(_raw, "type") && is_string(_raw.type)) {
        _entry.card_type = string_lower(string_trim(_raw.type));
    }

    var _resource_only = !variable_struct_exists(_entry, "tag")
        && !variable_struct_exists(_entry, "id")
        && !variable_struct_exists(_entry, "card_type");

    if (_resource_only) {
        if (_amount == 0) return undefined;
        return _entry;
    }

    if (_entry.amount <= 0) return undefined;

    return _entry;
}

function card_NormalizeCostsOnCard(_card) {
    if (_card == undefined) return;

    var _costs = [];
    var _had_costs_array = variable_struct_exists(_card, "costs")
        && is_array(_card.costs)
        && array_length(_card.costs) > 0;

    if (_had_costs_array) {
        for (var i = 0; i < array_length(_card.costs); i++) {
            var _entry = card_NormalizeCostEntry(_card.costs[i]);
            if (_entry != undefined) array_push(_costs, _entry);
        }
    }

    if (variable_struct_exists(_card, "cost")) {
        var _legacy = card_NormalizeCostEntry(_card.cost);
        if (_legacy != undefined) {
            var _needs_legacy = true;
            if (_had_costs_array && !card_CostEntryIsTribute(_legacy)) {
                for (var r = 0; r < array_length(_costs); r++) {
                    if (!card_CostEntryIsTribute(_costs[r])) {
                        _needs_legacy = false;
                        break;
                    }
                }
            }
            if (_needs_legacy) {
                if (_had_costs_array) array_insert(_costs, 0, _legacy);
                else array_push(_costs, _legacy);
            }
        }
    }

    _card.costs = _costs;
}

function card_GetCosts(_card) {
    if (_card == undefined) return [];
    if (!variable_struct_exists(_card, "costs") || !is_array(_card.costs)) return [];
    return _card.costs;
}

function card_CostEntryIsTribute(_entry) {
    if (_entry == undefined) return false;
    return variable_struct_exists(_entry, "tag")
        || variable_struct_exists(_entry, "id")
        || variable_struct_exists(_entry, "card_type");
}

function card_CostEntryMatchesCardType(_entry, _hand_card) {
    if (_entry == undefined || _hand_card == undefined) return false;
    if (!variable_struct_exists(_entry, "card_type")) return false;

    var _want = string_lower(string(_entry.card_type));
    if (_want == "monster") {
        return (_hand_card.type == "monster" || _hand_card.type == "special_monster");
    }
    return (_hand_card.type == _want);
}

function card_GetResourceCostTotal(_card) {
    var _total = 0;
    var _costs = card_GetCosts(_card);
    for (var i = 0; i < array_length(_costs); i++) {
        if (card_CostEntryIsTribute(_costs[i])) continue;
        _total += _costs[i].amount;
    }
    return max(0, _total);
}

function card_CostEntryMatchesHandCard(_entry, _hand_card) {
    if (_entry == undefined || _hand_card == undefined) return false;

    if (variable_struct_exists(_entry, "card_type")) {
        return card_CostEntryMatchesCardType(_entry, _hand_card);
    }

    if (variable_struct_exists(_entry, "tag")) {
        return card_HasAnyTag(_hand_card, [_entry.tag]);
    }

    if (variable_struct_exists(_entry, "id") && variable_struct_exists(_hand_card, "id")) {
        return floor(real(_hand_card.id)) == floor(real(_entry.id));
    }

    return false;
}

function card_CountAvailableTributes(_entry, _exclude_hand_index = -1) {
    if (_entry == undefined || !card_CostEntryIsTribute(_entry)) return 0;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return 0;

    var _need = max(1, _entry.amount);
    var _count = 0;

    with (_hand) {
        for (var i = 0; i < hand_Count; i++) {
            if (i == _exclude_hand_index) continue;
            if (card_CostEntryMatchesHandCard(_entry, hand[i])) {
                _count++;
            }
        }
    }

    return _count;
}

function card_CanAffordCostEntry(_entry, _exclude_hand_index = -1) {
    if (_entry == undefined) return true;

    if (card_CostEntryIsTribute(_entry)) {
        return card_CountAvailableTributes(_entry, _exclude_hand_index) >= max(1, _entry.amount);
    }

    return battle_CanAffordResources(_entry.amount);
}

function card_CanAffordAllCosts(_card, _exclude_hand_index = -1) {
    if (_card == undefined) return true;

    var _costs = card_GetCosts(_card);
    if (array_length(_costs) <= 0) return true;

    if (!battle_CanAffordResources(card_GetResourceCostTotal(_card))) return false;

    for (var i = 0; i < array_length(_costs); i++) {
        if (!card_CanAffordCostEntry(_costs[i], _exclude_hand_index)) return false;
    }

    return true;
}

function card_CollectTributeIndices(_entry, _exclude_hand_index) {
    var _indices = [];
    if (_entry == undefined || !card_CostEntryIsTribute(_entry)) return _indices;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return _indices;

    var _need = max(1, _entry.amount);

    with (_hand) {
        for (var i = 0; i < hand_Count && array_length(_indices) < _need; i++) {
            if (i == _exclude_hand_index) continue;
            if (card_CostEntryMatchesHandCard(_entry, hand[i])) {
                array_push(_indices, i);
            }
        }
    }

    return _indices;
}

function card_PayAllCosts(_card, _playing_hand_index = -1) {
    if (_card == undefined) return true;
    if (!card_CanAffordAllCosts(_card, _playing_hand_index)) return false;

    var _costs = card_GetCosts(_card);
    var _tribute_indices = [];

    for (var i = 0; i < array_length(_costs); i++) {
        var _indices = card_CollectTributeIndices(_costs[i], _playing_hand_index);
        for (var t = 0; t < array_length(_indices); t++) {
            array_push(_tribute_indices, _indices[t]);
        }
    }

    if (!battle_SpendResources(card_GetResourceCostTotal(_card))) return false;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand != noone) {
        with (_hand) {
            while (array_length(_tribute_indices) > 0) {
                var _max_idx = _tribute_indices[0];
                for (var r = 1; r < array_length(_tribute_indices); r++) {
                    if (_tribute_indices[r] > _max_idx) _max_idx = _tribute_indices[r];
                }
                hand_RemoveCard(_max_idx);
                for (var d = array_length(_tribute_indices) - 1; d >= 0; d--) {
                    if (_tribute_indices[d] == _max_idx) {
                        array_delete(_tribute_indices, d, 1);
                    }
                }
            }
        }
    }

    return true;
}

function card_AppendCostEntry(_card, _entry) {
    if (_card == undefined || _entry == undefined) return false;

    card_NormalizeCostsOnCard(_card);
    array_push(_card.costs, _entry);
    show_debug_message("Added cost to " + _card.name + ": " + card_FormatCostEntry(_entry));
    return true;
}

function card_BuildCostEntryFromTrait(_trait) {
    if (_trait == undefined) return undefined;

    var _amount = floor(real(_trait.amount));
    var _entry = { amount: _amount };

    if (_trait.card_id >= 0) {
        _entry.id = _trait.card_id;
    } else if (variable_struct_exists(_trait, "tags") && is_array(_trait.tags) && array_length(_trait.tags) > 0) {
        _entry.tag = string(_trait.tags[0]);
    }

    var _resource_only = !variable_struct_exists(_entry, "tag") && !variable_struct_exists(_entry, "id");
    if (_resource_only) {
        if (_amount == 0) return undefined;
        return _entry;
    }

    if (_amount <= 0) return undefined;

    return _entry;
}

function card_FormatCostEntry(_entry) {
    if (_entry == undefined) return "";

    if (variable_struct_exists(_entry, "tag")) {
        return string(_entry.amount) + "x [" + _entry.tag + "]";
    }

    if (variable_struct_exists(_entry, "id")) {
        return string(_entry.amount) + "x id " + string(_entry.id);
    }

    if (variable_struct_exists(_entry, "card_type")) {
        return string(_entry.amount) + "x " + _entry.card_type + " (hand)";
    }

    return string(_entry.amount) + " resources";
}

function card_FormatAllCosts(_card) {
    var _costs = card_GetCosts(_card);
    if (array_length(_costs) <= 0) return "";

    var _txt = "";
    for (var i = 0; i < array_length(_costs); i++) {
        if (i > 0) _txt += ", ";
        _txt += card_FormatCostEntry(_costs[i]);
    }
    return _txt;
}

function card_GetDefinitionResourceCost(_card) {
    if (_card == undefined || !variable_struct_exists(_card, "id")) return -1;

    var _def = deck_GetCardData(floor(real(_card.id)));
    if (_def == undefined) return -1;

    return card_GetResourceCostTotal(_def);
}

function card_FormatCostConditionLine(_entry) {
    if (_entry == undefined) return "";

    if (variable_struct_exists(_entry, "tag")) {
        return "Discard " + string(_entry.amount) + " " + _entry.tag;
    }

    if (variable_struct_exists(_entry, "id")) {
        return "Discard " + string(_entry.amount) + " " + deck_GetCardName(_entry.id);
    }

    if (variable_struct_exists(_entry, "card_type")) {
        return "Discard " + string(_entry.amount) + " " + _entry.card_type;
    }

    if (_entry.amount < 0) {
        return "Cost reduced by " + string(abs(_entry.amount)) + " resources";
    }

    return "Pay " + string(_entry.amount) + " resources";
}

function card_GetPlayCostConditionLines(_card) {
    var _lines = [];
    if (_card == undefined) return _lines;
    if (_card.type == "spirit" || _card.type == "special_monster") return _lines;

    card_NormalizeCostsOnCard(_card);
    var _costs = card_GetCosts(_card);
    var _resource_total = 0;
    var _tribute_lines = [];

    for (var i = 0; i < array_length(_costs); i++) {
        if (card_CostEntryIsTribute(_costs[i])) {
            array_push(_tribute_lines, card_FormatCostConditionLine(_costs[i]));
        } else {
            _resource_total += _costs[i].amount;
        }
    }

    _resource_total = max(0, _resource_total);
    if (_resource_total > 0) {
        var _base = card_GetDefinitionResourceCost(_card);
        if (_base >= 0 && _base != _resource_total) {
            array_push(_lines, "Pay " + string(_resource_total) + " resources (was " + string(_base) + ")");
        } else {
            array_push(_lines, "Pay " + string(_resource_total) + " resources");
        }
    }

    for (var t = 0; t < array_length(_tribute_lines); t++) {
        array_push(_lines, _tribute_lines[t]);
    }

    return _lines;
}
