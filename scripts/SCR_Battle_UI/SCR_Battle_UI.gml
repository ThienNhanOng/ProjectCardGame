/// @desc End Turn button + turn HUD helpers

function battle_GetEndTurnButtonRect() {
    return {
        left: 1146,
        top: BATTLE_UI_Y + 48,
        right: 1266,
        bottom: BATTLE_UI_Y + 98
    };
}

function battle_IsEndTurnButtonHovered() {
    var _rect = battle_GetEndTurnButtonRect();
    return (mouse_x >= _rect.left && mouse_x <= _rect.right &&
            mouse_y >= _rect.top && mouse_y <= _rect.bottom);
}

function battle_HandleEndTurnButton() {
    if (!mouse_check_button_pressed(mb_left)) return;
    if (!battle_IsEndTurnButtonHovered()) return;
    battle_EndTurn();
}

function SCR_Battle_UI_Draw() {
    battle_DrawPlayerHealthBar();
    battle_DrawResourcesCounter();

    var _rect = battle_GetEndTurnButtonRect();
    var _hover = battle_IsEndTurnButtonHovered();
    var _enabled = battle_CanEndTurn();

    // turn counter on the left of the bottom bar
    var _phase_text = battle_IsPlayerPhase() ? "Your turn" : "Enemy turn";
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(168, 151, 122));
    draw_text(105, BATTLE_UI_Y + 34, "TURN");
    draw_set_color(make_color_rgb(201, 162, 74));
    draw_text_transformed(105, BATTLE_UI_Y + 74, string(turn_number), 3, 3, 0);
    draw_set_color(make_color_rgb(239, 227, 196));
    draw_text(105, BATTLE_UI_Y + 118, _phase_text);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // brass button (dimmed while the enemies act)
    var _live = _enabled && !battle_IsEnemyPhase();
    var _top_col = _live ? (_hover ? make_color_rgb(230, 194, 106) : make_color_rgb(201, 162, 74)) : make_color_rgb(91, 80, 68);
    var _bot_col = _live ? make_color_rgb(141, 106, 38) : make_color_rgb(61, 53, 45);
    draw_rectangle_color(_rect.left, _rect.top, _rect.right, _rect.bottom, _top_col, _top_col, _bot_col, _bot_col, false);
    draw_set_color(make_color_rgb(26, 19, 13));
    draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
    draw_rectangle(_rect.left + 1, _rect.top + 1, _rect.right - 1, _rect.bottom - 1, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_live ? make_color_rgb(26, 19, 13) : make_color_rgb(154, 140, 120));
    draw_text((_rect.left + _rect.right) / 2, (_rect.top + _rect.bottom) / 2, battle_IsEnemyPhase() ? "Enemy turn" : "END TURN");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function battle_GetPreviewPanelLayout() {
    // far right, right under the battle log (battle_EnemyLog_GetPanelLayout)
    var _log = battle_EnemyLog_GetPanelLayout();
    var _top = _log.y + _log.h + 8;
    return {
        x: _log.x,
        y: _top,
        w: _log.w,
        h: BATTLE_UI_Y - 64 - _top
    };
}

function battle_IsEnemyPreviewCard(_card) {
    return (_card != undefined && variable_struct_exists(_card, "base_attack"));
}

function battle_FormatPreviewTurnCount(_turns) {
    var _count = max(0, floor(_turns));
    var _word = (_count == 1) ? "turn" : "turns";
    return string(_count) + " " + _word;
}

function battle_EnemyMonsterAttackPendingThisPhase(_slot_index) {
    if (_slot_index < 0 || !battle_IsEnemyPhase()) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;

    with (_bm) {
        if (!enemy_turn_active) return false;
        if (_slot_index > enemy_turn_slot_index) return true;
        if (_slot_index < enemy_turn_slot_index) return false;
        return enemy_turn_step_index <= 2;
    }
}

function battle_EnemyWillUseAttackAllSoon(_card, _slot_index) {
    if (_card == undefined || _slot_index < 0) return false;
    if (status_IsSilenced(_card)) return false;

    monsterAbility_InitState(_card);

    if (_card.attack_all_charges > 0) return true;

    if (_card.pending_delayed != undefined) return false;

    var _trait = monsterAbility_GetCurrentTrait(_card);
    if (_trait == undefined || _trait.type != "attack_all") return false;
    if (monsterAbility_GetDelay(_trait) > 0) return false;

    return true;
}

function battle_FindPlayerColumnForCard(_card) {
    var _column = battle_FindPlayerMonsterColumn(_card);
    if (_column >= 0) return _column;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _card == undefined) return -1;

    for (var w = 0; w < array_length(_board.player_weapon_slots); w++) {
        var _slot = _board.player_weapon_slots[w];
        if (_slot.visible && _slot.occupied && _slot.card == _card) return w;
    }
    return -1;
}

function battle_GetPreviewAttackAllLine(_card) {
    if (_card == undefined) return "";

    if (battle_IsEnemyPreviewCard(_card)) {
        var _slot = unit_FindSlotOfCard(SIDE_ENEMY, _card);
        if (_slot < 0) return "";

        if (!battle_EnemyWillUseAttackAllSoon(_card, _slot)) return "";

        if (battle_IsEnemyPhase() && battle_EnemyMonsterAttackPendingThisPhase(_slot)) {
            return "Will attack all this turn";
        }
        return "Will attack all next turn";
    }

    var _column = battle_FindPlayerColumnForCard(_card);
    if (_column < 0) return "";

    var _parts = battle_GetColumnStrikeParts(_column);
    if (_parts.weapon_attack_all <= 0 && _parts.monster_attack_all <= 0) return "";
    if (!battle_IsPlayerPhase() || !battle_CanColumnAttack(_column)) return "";

    return "Will attack all this turn";
}

function battle_AppendPreviewTimedEffectLines(_lines, _card) {
    if (_card == undefined) return _lines;

    var _attack_all_line = battle_GetPreviewAttackAllLine(_card);
    if (_attack_all_line != "") {
        array_push(_lines, _attack_all_line);
    }

    if (variable_struct_exists(_card, "timed_attack_buffs") && is_array(_card.timed_attack_buffs)) {
        for (var b = 0; b < array_length(_card.timed_attack_buffs); b++) {
            var _buff = _card.timed_attack_buffs[b];
            var _amount = max(0, floor(_buff.amount));
            var _turns = max(0, floor(_buff.turns_left));
            var _label = "Buff: atk +" + string(_amount);

            if (variable_struct_exists(_buff, "source_name") && string(_buff.source_name) != ""
                && string(_buff.source_name) != string(_card.name)) {
                _label = string(_buff.source_name) + "'s buff: atk +" + string(_amount);
            }

            array_push(_lines, _label + " (" + battle_FormatPreviewTurnCount(_turns) + ")");
        }
    }

    if (variable_struct_exists(_card, "pending_delayed") && _card.pending_delayed != undefined) {
        var _countdown = max(0, floor(_card.pending_delayed.countdown));
        if (_countdown > 0) {
            var _ability_name = _card.pending_delayed.display_name;
            array_push(_lines, _ability_name + ": " + battle_FormatPreviewTurnCount(_countdown) + " remaining");
        }
    }

    return _lines;
}

function battle_GetPreviewSummaryLines(_card) {
    if (battle_IsEnemyPreviewCard(_card)) {
        var _lines = [];
        array_push(_lines, "Type: enemy");
        if (monster_IsElite(_card)) array_push(_lines, "Elite");
        battle_EnsureCardHealth(_card);
        array_push(_lines, "HP: " + string(_card.health) + "/" + string(_card.max_health));

        var _atk = variable_struct_exists(_card, "attack") ? _card.attack : _card.base_attack;
        array_push(_lines, "Attack: " + string(max(_atk, card_GetSummaryTotalAttack(_card))));

        var _status = status_GetDisplayText(_card);
        if (_status != "") array_push(_lines, _status);

        _lines = battle_AppendPreviewTimedEffectLines(_lines, _card);
        return _lines;
    }

    var _lines = SCR_DBD_GetCardSummaryLines(_card);

    if (variable_struct_exists(_card, "health") && variable_struct_exists(_card, "max_health")) {
        battle_EnsureCardHealth(_card);
        for (var i = 0; i < array_length(_lines); i++) {
            if (string_copy(_lines[i], 1, 3) == "HP:") {
                _lines[i] = "HP: " + string(_card.health) + "/" + string(_card.max_health);
                break;
            }
        }
    }

    _lines = SCR_DBD_AppendAttackBuffSummaryLines(_lines, _card, battle_FindPlayerMonsterColumn(_card));
    _lines = battle_AppendPreviewTimedEffectLines(_lines, _card);

    var _player_status = status_GetDisplayText(_card);
    if (_player_status != "") array_push(_lines, _player_status);

    if (card_IsAstral(_card)) {
        array_push(_lines, "Astral — persists in extra deck");
    } else if (card_IsSpiritType(_card)
        && variable_struct_exists(_card, "board_turns_left")
        && _card.board_turns_left >= 0) {
        array_push(_lines, "Turns left: " + string(_card.board_turns_left));
    }

    return _lines;
}

function battle_GetPreviewAbilityLines(_card) {
    if (battle_IsEnemyPreviewCard(_card)) {
        if (status_IsSilenced(_card)) {
            return ["Silenced — cannot use abilities"];
        }

        var _traits = trait_GetFromMonster(_card);
        var _lines = [];
        for (var t = 0; t < array_length(_traits); t++) {
            if (_traits[t].type == "none") continue;
            array_push(_lines, SCR_DBD_FormatTraitLine(_traits[t]));
        }
        if (array_length(_lines) <= 0) array_push(_lines, "None");
        return _lines;
    }

    return SCR_DBD_GetCardAbilityLines(_card);
}

function battle_FindHoveredPreviewCard() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.is_dragging) return undefined;

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck != noone && _deck.tag_picker_open) {
        var _preview = undefined;
        with (_deck) {
            _preview = deck_ScrollPicker_GetPreviewCard(tag_picker_card_ids, tag_picker_scroll, tag_picker_focus);
        }
        if (_preview != undefined) return _preview;
    }

    if (_deck != noone && _deck.extra_deck_picker_open) {
        var _ids = [];
        var _preview = undefined;
        with (_deck) {
            _ids = deck_ExtraDeckPicker_GetExtraDeckIds();
            _preview = deck_ScrollPicker_GetPreviewCard(_ids, extra_deck_picker_scroll, extra_deck_picker_focus);
        }
        if (_preview != undefined) return _preview;
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone && _bm.monsterAbility_picker_active
        && _bm.monsterAbility_picker_mode == "discard_extra_deck") {
        if (_deck != noone) {
            var _ids = [];
            var _preview = undefined;
            with (_deck) _ids = deck_ExtraDeckPicker_GetExtraDeckIds();
            _preview = deck_ScrollPicker_GetPreviewCard(_ids, _bm.monsterAbility_picker_extra_scroll,
                _bm.monsterAbility_picker_extra_focus);
            if (_preview != undefined) return _preview;
        }
    }

    if (_bm != noone && _bm.spirit_shuffle_active && _bm.spirit_shuffle_phase == "pick_discard") {
        if (_deck != noone) {
            var _ids = [];
            var _preview = undefined;
            with (_deck) _ids = deck_ExtraDeckPicker_GetExtraDeckIds();
            with (_bm) {
                _preview = deck_ScrollPicker_GetPreviewCard(_ids, spirit_shuffle_extra_scroll, spirit_shuffle_extra_focus);
            }
            if (_preview != undefined) return _preview;
        }
    }

    var _enemy_slot = unit_GetSlotAt(SIDE_ENEMY, mouse_x, mouse_y);
    if (_enemy_slot >= 0) return unit_Get(SIDE_ENEMY, _enemy_slot);

    var _board_card = battle_FindPlayerCardAt(mouse_x, mouse_y, false);
    if (_board_card != undefined) return _board_card;

    return battle_FindHandCardAt(mouse_x, mouse_y);
}

function battle_DrawHoverPreview() {
    var _card = battle_FindHoveredPreviewCard();
    if (_card == undefined) return;

    var _title_color = c_white;
    if (battle_IsEnemyPreviewCard(_card) && monster_IsElite(_card)) {
        _title_color = c_red;
    }

    SCR_DBD_DrawCardPreviewPanel(
        battle_GetPreviewPanelLayout(),
        _card,
        battle_GetPreviewSummaryLines(_card),
        battle_GetPreviewAbilityLines(_card),
        _title_color,
        SCR_DBD_ShouldShowPreviewConditions(_card) ? SCR_DBD_GetCardConditionLines(_card) : undefined,
        true
    );
}
