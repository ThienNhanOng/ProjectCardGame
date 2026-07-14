/// @desc Conditions trait — spirit summon requirements from extra deck

function conditions_summon_Reset() {
    conditions_summon_active = false;
    conditions_summon_card_id = -1;
    conditions_summon_card = undefined;
    conditions_summon_return_entry = undefined;
    conditions_summon_queue = [];
    conditions_summon_mode = "none";
    conditions_summon_current = undefined;
    conditions_summon_picked_slots = [];
    conditions_summon_picked_hand = [];
    conditions_summon_pick_count = 0;
    conditions_summon_prompt = "";
}

function conditions_summon_IsActive() {
    return conditions_summon_active;
}

function conditions_NormalizeEntry(_raw) {
    var _type = variable_struct_exists(_raw, "type") ? string(_raw.type) : "";
    var _amount = 1;
    var _tags = [];
    var _slots = [];
    var _id = -1;

    if (variable_struct_exists(_raw, "amount")) _amount = _raw.amount;
    else if (variable_struct_exists(_raw, "value")) _amount = _raw.value;
    else if (variable_struct_exists(_raw, "count")) _amount = _raw.count;

    if (_type == "sacrifice_monster" || _type == "sacrifice_ally") _type = "sacrifice_monster";
    if (_type == "destroy_weapon" || _type == "destroy_weapons") _type = "destroy_weapons";
    if (_type == "min_turn" || _type == "turn_plus" || _type == "turn_minimum") _type = "min_turn";
    if (_type == "sacrifice_tag" || _type == "sacrifice_tags") _type = "sacrifice_tag";
    if (_type == "sacrifice_card" || _type == "sacrifice_cards") _type = "sacrifice_id";
    if (_type == "discard_tag" || _type == "discard_tags") _type = "discard_tag";
    if (_type == "astral" && _amount <= 0) _amount = 1;

    if (variable_struct_exists(_raw, "id")) _id = floor(real(_raw.id));
    else if (variable_struct_exists(_raw, "card_id")) _id = floor(real(_raw.card_id));

    if (variable_struct_exists(_raw, "tags") && is_array(_raw.tags)) {
        for (var t = 0; t < array_length(_raw.tags); t++) {
            array_push(_tags, string(_raw.tags[t]));
        }
    } else if (variable_struct_exists(_raw, "tag")) {
        array_push(_tags, string(_raw.tag));
    }

    if (variable_struct_exists(_raw, "slots") && is_array(_raw.slots)) {
        for (var s = 0; s < array_length(_raw.slots); s++) {
            array_push(_slots, _raw.slots[s] - 1);
        }
    }

    var _card_types = conditions_NormalizeCardTypes(_raw);

    return { type: _type, amount: max(1, floor(_amount)), tags: _tags, slots: _slots, id: _id, card_types: _card_types };
}

function conditions_NormalizeCardTypes(_raw) {
    var _types = [];

    if (variable_struct_exists(_raw, "types") && is_array(_raw.types)) {
        for (var i = 0; i < array_length(_raw.types); i++) {
            var _t = string_lower(string_trim(_raw.types[i]));
            if (_t == "" || _t == "any") continue;
            array_push(_types, _t);
        }
    } else if (variable_struct_exists(_raw, "card_types") && is_array(_raw.card_types)) {
        for (var i = 0; i < array_length(_raw.card_types); i++) {
            var _t = string_lower(string_trim(_raw.card_types[i]));
            if (_t == "" || _t == "any") continue;
            array_push(_types, _t);
        }
    } else if (variable_struct_exists(_raw, "card_type")) {
        var _single = string_lower(string_trim(_raw.card_type));
        if (_single != "" && _single != "any") array_push(_types, _single);
    }

    return _types;
}

function conditions_GetTrait(_card) {
    if (_card == undefined) return undefined;
    var _traits = trait_GetFromCard(_card);
    return trait_FindFirst(_traits, "conditions");
}

function conditions_GetRequirements(_card) {
    var _trait = conditions_GetTrait(_card);
    if (_trait == undefined) return [];
    if (!variable_struct_exists(_trait, "requirements") || !is_array(_trait.requirements)) return [];

    var _normalized = [];
    for (var i = 0; i < array_length(_trait.requirements); i++) {
        array_push(_normalized, conditions_NormalizeEntry(_trait.requirements[i]));
    }
    return _normalized;
}

function conditions_GetRequirementText(_cond) {
    if (_cond == undefined) return "";
    switch (_cond.type) {
        case "min_turn": return "Turn " + string(_cond.amount) + "+";
        case "sacrifice_monster":
            var _slot_txt = (array_length(_cond.slots) > 0) ? " (slots " + conditions_FormatSlots1Based(_cond.slots) + ")" : "";
            return "Sacrifice " + string(_cond.amount) + " ally monster(s)" + _slot_txt;
        case "destroy_weapons": return "Destroy " + string(_cond.amount) + " weapon(s)";
        case "sacrifice_tag":
            return "Sacrifice " + string(_cond.amount) + " [" + conditions_JoinTags(_cond.tags) + "] monster(s)";
        case "sacrifice_id":
            var _name = (_cond.id > 0) ? deck_GetCardName(_cond.id) : "card #" + string(_cond.id);
            return "Sacrifice " + string(_cond.amount) + " " + _name + "(s)";
        case "discard_action": return "Discard " + string(_cond.amount) + " action card(s)";
        case "discard_monster": return "Discard " + string(_cond.amount) + " monster card(s)";
        case "discard_weapon": return "Discard " + string(_cond.amount) + " weapon card(s)";
        case "discard_tag":
            var _type_label = conditions_FormatCardTypesLabel(_cond.card_types);
            return "Discard " + string(_cond.amount) + " [" + conditions_JoinTags(_cond.tags) + "] " + _type_label + " card(s)";
        case "astral":
            return "Astral — persists in extra deck";
        default: return string(_cond.type);
    }
}

function conditions_FormatSlots1Based(_slots) {
    var _txt = "";
    for (var i = 0; i < array_length(_slots); i++) {
        if (i > 0) _txt += ",";
        _txt += string(_slots[i] + 1);
    }
    return _txt;
}

function conditions_JoinTags(_tags) {
    var _txt = "";
    for (var i = 0; i < array_length(_tags); i++) {
        if (i > 0) _txt += ", ";
        _txt += _tags[i];
    }
    return _txt;
}

function conditions_FormatCardTypesLabel(_types) {
    if (!is_array(_types) || array_length(_types) <= 0) return "any type";
    var _txt = "";
    for (var i = 0; i < array_length(_types); i++) {
        if (i > 0) _txt += "/";
        _txt += _types[i];
    }
    return _txt;
}

function conditions_CardMatchesTypeFilter(_card, _type_filter) {
    if (_card == undefined) return false;
    if (!is_array(_type_filter) || array_length(_type_filter) <= 0) return true;

    for (var i = 0; i < array_length(_type_filter); i++) {
        var _want = _type_filter[i];
        if (_want == "monster") {
            if (_card.type == "monster" || _card.type == "special_monster") return true;
        } else if (_card.type == _want) {
            return true;
        }
    }
    return false;
}

function conditions_CardHasTag(_card, _tags) {
    if (_card == undefined || array_length(_tags) <= 0) return false;
    if (!variable_struct_exists(_card, "tag") || !is_array(_card.tag)) return false;

    for (var t = 0; t < array_length(_tags); t++) {
        var _want = string_lower(string_trim(_tags[t]));
        for (var c = 0; c < array_length(_card.tag); c++) {
            if (string_lower(string(_card.tag[c])) == _want) return true;
        }
    }
    return false;
}

function conditions_HandCountOfType(_type) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return 0;

    var _count = 0;
    with (_hand) {
        for (var i = 0; i < hand_Count; i++) {
            if (hand[i] != undefined && hand[i].type == _type) _count++;
        }
    }
    return _count;
}

function conditions_CountHandDiscardTagCandidates(_tags, _type_filter) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return 0;

    var _count = 0;
    with (_hand) {
        for (var i = 0; i < hand_Count; i++) {
            if (hand[i] == undefined) continue;
            if (!conditions_CardHasTag(hand[i], _tags)) continue;
            if (!conditions_CardMatchesTypeFilter(hand[i], _type_filter)) continue;
            _count++;
        }
    }
    return _count;
}

function conditions_CardMatchesId(_card, _card_id) {
    if (_card == undefined || _card_id <= 0) return false;
    if (!variable_struct_exists(_card, "id")) return false;
    return floor(real(_card.id)) == floor(real(_card_id));
}

function conditions_CountOccupiedMonsters(_tags, _slots_filter) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    var _count = 0;
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        if (array_length(_slots_filter) > 0 && !conditions_SlotInList(i, _slots_filter)) continue;
        if (array_length(_tags) > 0 && !conditions_CardHasTag(_slot.card, _tags)) continue;
        _count++;
    }
    return _count;
}

function conditions_CountOccupiedMonstersById(_card_id) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    var _count = 0;
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        if (!conditions_CardMatchesId(_slot.card, _card_id)) continue;
        _count++;
    }
    return _count;
}

function conditions_CountHandCardsById(_card_id) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return 0;

    var _count = 0;
    with (_hand) {
        for (var i = 0; i < hand_Count; i++) {
            if (conditions_CardMatchesId(hand[i], _card_id)) _count++;
        }
    }
    return _count;
}

function conditions_CountSacrificeCandidatesById(_card_id) {
    return conditions_CountOccupiedMonstersById(_card_id) + conditions_CountHandCardsById(_card_id);
}

function conditions_SlotInList(_index, _list) {
    for (var i = 0; i < array_length(_list); i++) {
        if (_list[i] == _index) return true;
    }
    return false;
}

function conditions_CountOccupiedWeapons() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    var _count = 0;
    for (var i = 0; i < array_length(_board.player_weapon_slots); i++) {
        var _slot = _board.player_weapon_slots[i];
        if (_slot.visible && _slot.occupied && _slot.card != undefined) _count++;
    }
    return _count;
}

function conditions_FindEmptyMonsterSlot() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return -1;

    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (_slot.visible && !_slot.locked && !_slot.occupied) return i;
    }
    return -1;
}

function conditions_CountEmptyMonsterSlots() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 0;

    var _count = 0;
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (_slot.visible && !_slot.locked && !_slot.occupied) _count++;
    }
    return _count;
}

function conditions_HasRoomToSummon(_card) {
    if (_card == undefined) return false;

    var _empty = conditions_CountEmptyMonsterSlots();
    if (_empty > 0) return true;

    var _conds = conditions_GetRequirements(_card);
    for (var i = 0; i < array_length(_conds); i++) {
        var _cond = _conds[i];
        if (_cond.type == "sacrifice_monster" || _cond.type == "sacrifice_tag") {
            if (conditions_CountOccupiedMonsters(
                (_cond.type == "sacrifice_tag") ? _cond.tags : [],
                _cond.slots) >= _cond.amount) {
                return true;
            }
        } else if (_cond.type == "sacrifice_id") {
            if (conditions_CountOccupiedMonstersById(_cond.id) >= _cond.amount) return true;
        }
    }
    return false;
}

function conditions_CanMeetRequirement(_cond) {
    if (_cond == undefined) return true;

    switch (_cond.type) {
        case "min_turn":
            return turn_number >= _cond.amount;
        case "sacrifice_monster":
            return conditions_CountOccupiedMonsters([], _cond.slots) >= _cond.amount;
        case "destroy_weapons":
            return conditions_CountOccupiedWeapons() >= _cond.amount;
        case "sacrifice_tag":
            return conditions_CountOccupiedMonsters(_cond.tags, []) >= _cond.amount;
        case "sacrifice_id":
            if (conditions_CountSacrificeCandidatesById(_cond.id) < _cond.amount) return false;
            if (conditions_CountEmptyMonsterSlots() > 0) return true;
            return conditions_CountOccupiedMonstersById(_cond.id) >= _cond.amount;
        case "discard_action":
            return conditions_HandCountOfType("action") >= _cond.amount;
        case "discard_monster":
            return conditions_HandCountOfType("monster") + conditions_HandCountOfType("special_monster") >= _cond.amount;
        case "discard_weapon":
            return conditions_HandCountOfType("weapon") >= _cond.amount;
        case "discard_tag":
            return conditions_CountHandDiscardTagCandidates(_cond.tags, _cond.card_types) >= _cond.amount;
        case "astral":
            return true;
        default:
            return true;
    }
}

function conditions_GetSummonFailReason(_card) {
    if (_card == undefined) return "invalid card";
    if (!conditions_HasRoomToSummon(_card)) {
        return "no board space (need an empty slot or monsters to sacrifice)";
    }

    var _conds = conditions_GetRequirements(_card);
    for (var i = 0; i < array_length(_conds); i++) {
        if (!conditions_CanMeetRequirement(_conds[i])) {
            return "still need: " + conditions_GetRequirementText(_conds[i]);
        }
    }
    return "";
}

/// @desc True when this spirit persists in the extra deck unless it dies on board
function card_IsAstral(_card_or_id) {
    return card_HasAstralCondition(_card_or_id);
}

function conditions_CanSummon(_card) {
    if (_card == undefined) return false;
    if (!conditions_HasRoomToSummon(_card)) return false;

    var _conds = conditions_GetRequirements(_card);
    for (var i = 0; i < array_length(_conds); i++) {
        if (!conditions_CanMeetRequirement(_conds[i])) return false;
    }
    return true;
}

function conditions_TryBeginFromExtraDeck(_deck_index) {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;

    var _entry = undefined;
    with (_deck) _entry = deck_RemoveExtraCardAt(_deck_index, false);
    if (_entry == undefined) return false;

    var _card_id = extraDeck_GetCardId(_entry);
    if (_card_id <= 0) return false;

    var _card = deck_CreateRuntimeCard(_card_id);
    if (_card == undefined) {
        with (_deck) deck_AddExtraCardEntry(_entry);
        return false;
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) {
        with (_deck) deck_AddExtraCardEntry(_entry);
        return false;
    }

    var _ok = false;
    with (_bm) {
        _ok = conditions_BeginSummon(_card_id, _card, _entry);
    }

    if (_ok) {
        with (_deck) deck_ExtraDeckPicker_Close();
    } else {
        with (_deck) deck_AddExtraCardEntry(_entry);
    }
    return _ok;
}

function conditions_BeginSummon(_card_id, _runtime_card, _return_entry = undefined) {
    conditions_summon_Reset();
    if (_runtime_card == undefined) return false;

    if (!conditions_CanSummon(_runtime_card)) return false;

    conditions_summon_active = true;
    conditions_summon_card_id = _card_id;
    conditions_summon_card = _runtime_card;
    conditions_summon_return_entry = _return_entry;

    var _conds = conditions_GetRequirements(_runtime_card);
    for (var i = 0; i < array_length(_conds); i++) {
        if (_conds[i].type == "min_turn" || _conds[i].type == "astral") continue;
        array_push(conditions_summon_queue, _conds[i]);
    }

    conditions_ProcessNext();
    return true;
}

function conditions_CancelSummon() {
    if (!conditions_summon_active) return;

    if (conditions_summon_return_entry != undefined) {
        var _deck = instance_find(OBJ_Deck, 0);
        if (_deck != noone) {
            with (_deck) deck_AddExtraCardEntry(conditions_summon_return_entry);
        }
}
    conditions_summon_Reset();
}

function conditions_ProcessNext() {
    conditions_summon_picked_slots = [];
    conditions_summon_picked_hand = [];
    conditions_summon_pick_count = 0;
    conditions_summon_current = undefined;
    conditions_summon_mode = "none";
    conditions_summon_prompt = "";

    if (array_length(conditions_summon_queue) <= 0) {
        conditions_summon_mode = "pick_slot";
        conditions_summon_prompt = "Choose an empty monster slot to summon " + conditions_summon_card.name;
        return;
    }

    var _cond = conditions_summon_queue[0];
    conditions_summon_current = _cond;

    switch (_cond.type) {
        case "destroy_weapons":
            if (conditions_AutoDestroyWeapons(_cond.amount)) {
                array_delete(conditions_summon_queue, 0, 1);
                conditions_ProcessNext();
            } else {
                conditions_CancelSummon();
            }
            break;

        case "sacrifice_monster":
            conditions_summon_mode = "sacrifice_monster";
            conditions_summon_prompt = "Select " + string(_cond.amount) + " ally monster(s) to sacrifice";
            break;

        case "sacrifice_tag":
            conditions_summon_mode = "sacrifice_tag";
            conditions_summon_prompt = "Select " + string(_cond.amount) + " [" + conditions_JoinTags(_cond.tags) + "] monster(s) to sacrifice";
            break;

        case "sacrifice_id":
            conditions_summon_mode = "sacrifice_id";
            var _sac_name = (_cond.id > 0) ? deck_GetCardName(_cond.id) : "card #" + string(_cond.id);
            conditions_summon_prompt = "Select " + string(_cond.amount) + " " + _sac_name + "(s) from board or hand";
            break;

        case "discard_action":
            conditions_summon_mode = "discard_hand";
            conditions_summon_prompt = "Select " + string(_cond.amount) + " action card(s) to discard";
            break;

        case "discard_monster":
            conditions_summon_mode = "discard_hand";
            conditions_summon_prompt = "Select " + string(_cond.amount) + " monster card(s) to discard";
            break;

        case "discard_weapon":
            conditions_summon_mode = "discard_hand";
            conditions_summon_prompt = "Select " + string(_cond.amount) + " weapon card(s) to discard";
            break;

        case "discard_tag":
            conditions_summon_mode = "discard_tag";
            var _discard_type_label = conditions_FormatCardTypesLabel(_cond.card_types);
            conditions_summon_prompt = "Select " + string(_cond.amount) + " [" + conditions_JoinTags(_cond.tags) + "] " + _discard_type_label + " card(s) to discard";
            break;

        default:
            array_delete(conditions_summon_queue, 0, 1);
            conditions_ProcessNext();
            break;
    }
}

function conditions_AutoDestroyWeapons(_amount) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    var _destroyed = 0;
    for (var i = 0; i < array_length(_board.player_weapon_slots) && _destroyed < _amount; i++) {
        var _slot = _board.player_weapon_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;

        with (_board) SCR_Board_RemoveCard(_slot);
        _destroyed++;
    }
    return _destroyed >= _amount;
}

function conditions_SlotAlreadyPicked(_index) {
    for (var i = 0; i < array_length(conditions_summon_picked_slots); i++) {
        if (conditions_summon_picked_slots[i] == _index) return true;
    }
    return false;
}

function conditions_IsValidSacrificeSlot(_slot_index) {
    if (conditions_summon_current == undefined) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.visible || !_slot.occupied || _slot.card == undefined) return false;
    if (conditions_SlotAlreadyPicked(_slot_index)) return false;

    if (conditions_summon_mode == "sacrifice_tag") {
        if (!conditions_CardHasTag(_slot.card, conditions_summon_current.tags)) return false;
    }

    if (conditions_summon_mode == "sacrifice_id") {
        if (!conditions_CardMatchesId(_slot.card, conditions_summon_current.id)) return false;
    }

    if (conditions_summon_mode == "sacrifice_monster" && array_length(conditions_summon_current.slots) > 0) {
        if (!conditions_SlotInList(_slot_index, conditions_summon_current.slots)) return false;
    }

    return true;
}

function conditions_IsValidDiscardHandIndex(_index, _required_type) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return false;
    if (_index < 0 || _index >= _hand.hand_Count) return false;

    var _card = _hand.hand[_index];
    if (_card == undefined) return false;

    if (_required_type == "monster") {
        return (_card.type == "monster" || _card.type == "special_monster");
    }
    return _card.type == _required_type;
}

function conditions_IsValidDiscardTagHandIndex(_index) {
    if (conditions_summon_mode != "discard_tag") return false;
    if (conditions_summon_current == undefined) return false;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return false;
    if (_index < 0 || _index >= _hand.hand_Count) return false;

    var _card = _hand.hand[_index];
    if (_card == undefined) return false;
    if (!conditions_CardHasTag(_card, conditions_summon_current.tags)) return false;
    return conditions_CardMatchesTypeFilter(_card, conditions_summon_current.card_types);
}

function conditions_GetDiscardRequiredType() {
    if (conditions_summon_current == undefined) return "";
    switch (conditions_summon_current.type) {
        case "discard_action": return "action";
        case "discard_monster": return "monster";
        case "discard_weapon": return "weapon";
    }
    return "";
}

function conditions_ExecuteSacrifices() {
    for (var i = 0; i < array_length(conditions_summon_picked_slots); i++) {
        battle_DestroyPlayerMonster(conditions_summon_picked_slots[i]);
    }

    if (array_length(conditions_summon_picked_hand) <= 0) return;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return;

    var _sorted = [];
    for (var h = 0; h < array_length(conditions_summon_picked_hand); h++) {
        array_push(_sorted, conditions_summon_picked_hand[h]);
    }
    array_sort(_sorted, true);

    with (_hand) {
        for (var s = 0; s < array_length(_sorted); s++) {
            hand_RemoveCard(_sorted[s]);
        }
    }
}

function conditions_CompleteSummonOnSlot(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;
    if (_slot_index < 0 || _slot_index >= array_length(_board.player_monster_slots)) return false;

    var _slot = _board.player_monster_slots[_slot_index];
    if (!_slot.visible || _slot.locked || _slot.occupied) return false;

    var _summon_card = conditions_summon_card;
    _summon_card.type = "special_monster";
    battle_EnsureCardHealth(_summon_card);

    var _placed = false;
    with (_board) _placed = SCR_Board_PlaceCard(_slot, _summon_card);

    if (_placed) {
        conditions_summon_Reset();
    }
    return _placed;
}

function conditions_HandIndexAlreadyPicked(_index) {
    for (var i = 0; i < array_length(conditions_summon_picked_hand); i++) {
        if (conditions_summon_picked_hand[i] == _index) return true;
    }
    return false;
}

function conditions_IsValidSacrificeHandIndex(_index) {
    if (conditions_summon_mode != "sacrifice_id") return false;
    if (conditions_summon_current == undefined) return false;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return false;
    if (_index < 0 || _index >= _hand.hand_Count) return false;

    var _card = _hand.hand[_index];
    if (_card == undefined) return false;
    if (conditions_HandIndexAlreadyPicked(_index)) return false;

    return conditions_CardMatchesId(_card, conditions_summon_current.id);
}

function conditions_SacrificePickCount() {
    return array_length(conditions_summon_picked_slots) + array_length(conditions_summon_picked_hand);
}

function conditions_TryPickSacrificeSlot(_slot_index) {
    if (!conditions_IsValidSacrificeSlot(_slot_index)) return false;

    array_push(conditions_summon_picked_slots, _slot_index);
    if (conditions_SacrificePickCount() < conditions_summon_current.amount) return true;

    conditions_ExecuteSacrifices();
    array_delete(conditions_summon_queue, 0, 1);
    conditions_ProcessNext();
    return true;
}

function conditions_TryPickSacrificeHand(_index) {
    if (!conditions_IsValidSacrificeHandIndex(_index)) return false;

    array_push(conditions_summon_picked_hand, _index);
    if (conditions_SacrificePickCount() < conditions_summon_current.amount) return true;

    conditions_ExecuteSacrifices();
    array_delete(conditions_summon_queue, 0, 1);
    conditions_ProcessNext();
    return true;
}

function conditions_TryPickDiscardHand(_index) {
    var _valid = false;
    if (conditions_summon_mode == "discard_tag") {
        _valid = conditions_IsValidDiscardTagHandIndex(_index);
    } else {
        var _req = conditions_GetDiscardRequiredType();
        _valid = conditions_IsValidDiscardHandIndex(_index, _req);
    }
    if (!_valid) return false;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return false;

    with (_hand) hand_RemoveCard(_index);
    conditions_summon_pick_count++;

    if (conditions_summon_pick_count < conditions_summon_current.amount) return true;

    array_delete(conditions_summon_queue, 0, 1);
    conditions_ProcessNext();
    return true;
}

function conditions_summon_CanCancel() {
    return conditions_summon_mode != "discard_hand" && conditions_summon_mode != "discard_tag";
}

function conditions_summon_Step() {
    if (!conditions_summon_active) return;

    if (conditions_summon_CanCancel()
        && (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right))) {
        conditions_CancelSummon();
        return;
    }

    if (!mouse_check_button_pressed(mb_left)) return;

    if (conditions_summon_mode == "pick_slot") {
        var _slot = conditions_GetMonsterSlotAt(mouse_x, mouse_y);
        if (_slot >= 0) {
            if (conditions_CompleteSummonOnSlot(_slot)) {
                battle_SkipFollowUpInputThisFrame();
            } else {
}
        }
        return;
    }

    if (conditions_summon_mode == "sacrifice_monster" || conditions_summon_mode == "sacrifice_tag" || conditions_summon_mode == "sacrifice_id") {
        var _sac_slot = conditions_GetMonsterSlotAt(mouse_x, mouse_y);
        if (_sac_slot >= 0) {
            if (conditions_TryPickSacrificeSlot(_sac_slot)) {
                battle_SkipFollowUpInputThisFrame();
            }
            return;
        }

        if (conditions_summon_mode == "sacrifice_id") {
            var _hand = instance_find(OBJ_Hand, 0);
            if (_hand != noone) {
                var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
                var _idx = SCR_Hand_PickCardIndex(mouse_x, mouse_y, _hand.hand_Count, _spacing, _hand.hand_Y);
                if (_idx >= 0 && conditions_TryPickSacrificeHand(_idx)) {
                    battle_SkipFollowUpInputThisFrame();
                }
            }
        }
        return;
    }

    if (conditions_summon_mode == "discard_hand" || conditions_summon_mode == "discard_tag") {
        var _hand = instance_find(OBJ_Hand, 0);
        if (_hand == noone) return;
        var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
        var _idx = SCR_Hand_PickCardIndex(mouse_x, mouse_y, _hand.hand_Count, _spacing, _hand.hand_Y);
        if (_idx >= 0 && conditions_TryPickDiscardHand(_idx)) {
            battle_SkipFollowUpInputThisFrame();
        }
    }
}

function conditions_GetMonsterSlotAt(_mx, _my) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return -1;

    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible) continue;
        if (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
            _my >= _slot.y && _my <= _slot.y + _slot.h) {
            return i;
        }
    }
    return -1;
}

function conditions_summon_Draw() {
    if (!conditions_summon_active) return;

    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    var _hint = conditions_summon_CanCancel() ? "  (ESC to cancel)" : "";
    draw_text(room_width / 2, 8, conditions_summon_prompt + _hint);
    draw_set_halign(fa_left);

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    if (conditions_summon_mode == "pick_slot") {
        for (var e = 0; e < array_length(_board.player_monster_slots); e++) {
            var _eslot = _board.player_monster_slots[e];
            if (!_eslot.visible || _eslot.locked || _eslot.occupied) continue;
            draw_set_color(c_lime);
            draw_rectangle(_eslot.x, _eslot.y, _eslot.x + _eslot.w, _eslot.y + _eslot.h, true);
        }
    }

    if (conditions_summon_mode == "sacrifice_monster" || conditions_summon_mode == "sacrifice_tag" || conditions_summon_mode == "sacrifice_id") {
        for (var s = 0; s < array_length(_board.player_monster_slots); s++) {
            if (!conditions_IsValidSacrificeSlot(s)) continue;
            var _sslot = _board.player_monster_slots[s];
            draw_set_color(c_orange);
            draw_rectangle(_sslot.x, _sslot.y, _sslot.x + _sslot.w, _sslot.y + _sslot.h, true);
        }
    }

    if (conditions_summon_mode == "sacrifice_id") {
        var _hand = instance_find(OBJ_Hand, 0);
        if (_hand != noone) {
            var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
            var _start_x = SCR_Hand_GetStartX(_hand.hand_Count, _spacing);

            for (var sh = 0; sh < _hand.hand_Count; sh++) {
                if (!conditions_IsValidSacrificeHandIndex(sh)) continue;
                var _hbox = SCR_Hand_GetCardHitbox(sh, _hand.hand_Count, _spacing, _hand.hand_Y, _start_x, false);
                draw_set_color(c_orange);
                draw_rectangle(_hbox.left, _hbox.top, _hbox.right, _hbox.bottom, true);
            }
        }
    }

    if (conditions_summon_mode == "discard_hand" || conditions_summon_mode == "discard_tag") {
        var _hand = instance_find(OBJ_Hand, 0);
        if (_hand == noone) return;

        var _req = conditions_GetDiscardRequiredType();
        var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
        var _start_x = SCR_Hand_GetStartX(_hand.hand_Count, _spacing);

        for (var h = 0; h < _hand.hand_Count; h++) {
            var _discard_ok = (conditions_summon_mode == "discard_tag")
                ? conditions_IsValidDiscardTagHandIndex(h)
                : conditions_IsValidDiscardHandIndex(h, _req);
            if (!_discard_ok) continue;
            var _box = SCR_Hand_GetCardHitbox(h, _hand.hand_Count, _spacing, _hand.hand_Y, _start_x, false);
            draw_set_color(c_red);
            draw_rectangle(_box.left, _box.top, _box.right, _box.bottom, true);
        }
    }

    draw_set_color(c_white);
}
