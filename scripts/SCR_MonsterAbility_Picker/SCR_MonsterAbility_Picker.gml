/// @desc Player choice UI during enemy turn (discard hand / extra deck)

function monsterAbility_Picker_Reset() {
    monsterAbility_picker_active = false;
    monsterAbility_picker_mode = "";
    monsterAbility_picker_remaining = 0;
    monsterAbility_picker_prompt = "";
    monsterAbility_picker_hand_filter = "";
    monsterAbility_picker_extra_scroll = 0;
    monsterAbility_picker_extra_focus = 0;
    monsterAbility_picker_source_slot = -1;
    monsterAbility_picker_source_trait = undefined;
}

function monsterAbility_Picker_Init() {
    monsterAbility_Picker_Reset();
    enemy_turn_picker_pause = false;
}

function monsterAbility_Picker_IsActive() {
    return monsterAbility_picker_active;
}

function monsterAbility_Picker_Begin(_mode, _count, _prompt, _hand_filter = "", _source_slot = -1, _source_trait = undefined) {
    monsterAbility_picker_active = true;
    monsterAbility_picker_mode = _mode;
    monsterAbility_picker_remaining = max(1, _count);
    monsterAbility_picker_prompt = _prompt;
    monsterAbility_picker_hand_filter = _hand_filter;
    monsterAbility_picker_extra_scroll = 0;
    monsterAbility_picker_extra_focus = 0;
    monsterAbility_picker_source_slot = _source_slot;
    monsterAbility_picker_source_trait = _source_trait;
    enemy_turn_picker_pause = true;
    enemy_turn_waiting = true;
}

function monsterAbility_Picker_Finish() {
    var _source_slot = monsterAbility_picker_source_slot;
    var _source_trait = monsterAbility_picker_source_trait;

    monsterAbility_Picker_Reset();
    enemy_turn_picker_pause = false;
    enemy_turn_waiting = false;

    var _monster = battle_EnemyTurn_GetLiveMonster(_source_slot);
    if (_monster != undefined && _source_trait != undefined) {
        monsterAbility_TryRestartDelayed(_source_slot, _monster, _source_trait);
    }

    battle_EnemyTurn_QueueDelay();
}

function monsterAbility_Picker_HandIndexValid(_index) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return false;
    if (_index < 0 || _index >= _hand.hand_Count) return false;

    var _card = _hand.hand[_index];
    if (_card == undefined) return false;
    if (monsterAbility_picker_hand_filter == "") return true;

    if (monsterAbility_picker_hand_filter == "monster") {
        return (_card.type == "monster" || _card.type == "special_monster");
    }
    return _card.type == monsterAbility_picker_hand_filter;
}

function monsterAbility_Picker_TryDiscardHand(_index) {
    if (!monsterAbility_Picker_HandIndexValid(_index)) return false;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone) return false;

    with (_hand) hand_RemoveCard(_index);
    monsterAbility_picker_remaining--;

    if (monsterAbility_picker_remaining > 0) return true;
    monsterAbility_Picker_Finish();
    return true;
}

function monsterAbility_Picker_TryDiscardExtra(_index) {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;
    if (_index < 0 || _index >= _deck.extra_deck_Count) return false;

    with (_deck) deck_RemoveExtraCardAt(_index);
    monsterAbility_picker_remaining--;

    if (monsterAbility_picker_remaining > 0) return true;
    monsterAbility_Picker_Finish();
    return true;
}

function monsterAbility_Picker_Step() {
    if (!monsterAbility_picker_active) return;

    if (monsterAbility_picker_mode == "discard_extra_deck") {
        var _deck = instance_find(OBJ_Deck, 0);
        if (_deck != noone) {
            var _ids = [];
            with (_deck) _ids = deck_ExtraDeckPicker_GetExtraDeckIds();
            var _input = deck_ScrollPicker_ApplyScrollInput(_ids, monsterAbility_picker_extra_scroll, monsterAbility_picker_extra_focus);
            monsterAbility_picker_extra_scroll = _input.scroll;
            monsterAbility_picker_extra_focus = _input.focus;
        }
    }

    if (!mouse_check_button_pressed(mb_left)) return;

    if (monsterAbility_picker_mode == "discard_hand") {
        var _hand = instance_find(OBJ_Hand, 0);
        if (_hand == noone) {
            monsterAbility_Picker_Finish();
            return;
        }
        var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
        var _idx = SCR_Hand_PickCardIndex(mouse_x, mouse_y, _hand.hand_Count, _spacing, _hand.hand_Y);
        if (_idx >= 0 && monsterAbility_Picker_TryDiscardHand(_idx)) {
            battle_SkipFollowUpInputThisFrame();
        }
        return;
    }

    if (monsterAbility_picker_mode == "discard_extra_deck") {
        var _deck = instance_find(OBJ_Deck, 0);
        if (_deck == noone || _deck.extra_deck_Count <= 0) {
            monsterAbility_Picker_Finish();
            return;
        }
        var _idx = -1;
        with (_deck) {
            _idx = deck_ExtraDeckPicker_PickIndexAt(mouse_x, mouse_y);
        }
        if (_idx >= 0 && monsterAbility_Picker_TryDiscardExtra(_idx)) {
            battle_SkipFollowUpInputThisFrame();
        }
    }
}

function monsterAbility_Picker_Draw() {
    if (!monsterAbility_picker_active) return;

    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    draw_text(room_width / 2, 8, monsterAbility_picker_prompt);
    draw_set_halign(fa_left);

    if (monsterAbility_picker_mode == "discard_extra_deck") {
        var _deck = instance_find(OBJ_Deck, 0);
        if (_deck == noone) return;

        var _ids = [];
        with (_deck) _ids = deck_ExtraDeckPicker_GetExtraDeckIds();

        deck_ScrollPicker_DrawPanel("Choose card to discard", _ids, monsterAbility_picker_extra_scroll,
            monsterAbility_picker_extra_focus, "No cards in extra deck", "Click card to discard", true);
    }
}
