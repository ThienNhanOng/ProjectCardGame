/// @desc End Turn button + turn HUD helpers

function battle_GetEndTurnButtonRect() {
    var _deck = instance_find(OBJ_Deck, 0);
    var _left = 600;

    if (_deck != noone) {
        _left = _deck.deck_X + 52;
    }

    return {
        left: _left,
        top: 585,
        right: _left + 120,
        bottom: 633
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

    var _phase_text = battle_IsPlayerPhase() ? "Your turn" : "Enemy turn";
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(_rect.left, _rect.top - 32, "Turn " + string(turn_number) + " — " + _phase_text);

    if (battle_IsEnemyPhase()) {
        draw_set_color(c_ltgray);
        draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text((_rect.left + _rect.right) / 2, (_rect.top + _rect.bottom) / 2, "Enemy...");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        return;
    }

    if (_enabled && _hover) draw_set_color(c_yellow);
    else if (_enabled) draw_set_color(c_white);
    else draw_set_color(c_gray);

    draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);

    if (_enabled && _hover) {
        draw_set_color(c_orange);
        draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_enabled ? c_black : c_dkgray);
    draw_text((_rect.left + _rect.right) / 2, (_rect.top + _rect.bottom) / 2, "End Turn");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function battle_GetPreviewPanelLayout() {
    var _field_right = sprite_get_width(SPR_Field);
    var _field_bottom = sprite_get_height(SPR_Field);
    var _gap = 10;
    var _y = 38;
    var _bottom_pad = 12;
    return {
        x: _field_right + _gap,
        y: _y,
        w: 250,
        h: max(420, _field_bottom - _y - _bottom_pad)
    };
}

function battle_IsEnemyPreviewCard(_card) {
    return (_card != undefined && variable_struct_exists(_card, "base_attack"));
}

function battle_GetPreviewSummaryLines(_card) {
    if (battle_IsEnemyPreviewCard(_card)) {
        var _lines = [];
        array_push(_lines, "Type: enemy");
        if (monster_IsElite(_card)) array_push(_lines, "Elite");
        battle_EnsureCardHealth(_card);
        array_push(_lines, "HP: " + string(_card.health) + "/" + string(_card.max_health));

        var _buff = card_GetAttackBuff(_card);
        if (_buff > 0) {
            array_push(_lines, "ATK buff: +" + string(_buff));
            array_push(_lines, "Attack: " + string(card_GetSummaryTotalAttack(_card)));
        } else {
            var _atk = variable_struct_exists(_card, "attack") ? _card.attack : _card.base_attack;
            array_push(_lines, "Attack: " + string(_atk));
        }

        var _status = status_GetDisplayText(_card);
        if (_status != "") array_push(_lines, _status);
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

    var _player_status = status_GetDisplayText(_card);
    if (_player_status != "") array_push(_lines, _player_status);

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
        var _idx = -1;
        with (_deck) {
            _idx = deck_ScrollPicker_PickIndexAt(mouse_x, mouse_y, tag_picker_card_ids, tag_picker_scroll);
            if (_idx >= 0) return deck_GetCardData(tag_picker_card_ids[_idx]);
        }
        return undefined;
    }

    if (_deck != noone && _deck.extra_deck_picker_open) {
        var _idx = -1;
        with (_deck) _idx = deck_ExtraDeckPicker_PickIndexAt(mouse_x, mouse_y);
        if (_idx >= 0) return deck_GetCardData(_deck.extra_deck[_idx]);
        return undefined;
    }

    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_mm != noone && _board != noone) {
        for (var e = 0; e < _mm.active_slot_count; e++) {
            var _eslot = _board.enemy_slots[e];
            if (!_eslot.visible || !_eslot.occupied || _eslot.card == undefined || !_eslot.card.alive) continue;
            if (monster_IsMouseOverSlot(_eslot)) return _eslot.card;
        }
    }

    if (_board != noone) {
        var _found = undefined;
        with (_board) {
            if (action_slot.visible && action_slot.occupied && action_slot.card != undefined
                && SCR_Board_IsSlotMouseOver(action_slot)) {
                _found = action_slot.card;
            }

            if (_found == undefined) {
                for (var w = 0; w < array_length(player_weapon_slots); w++) {
                    var _wslot = player_weapon_slots[w];
                    if (!_wslot.visible || !_wslot.occupied || _wslot.card == undefined) continue;
                    if (SCR_Board_IsSlotMouseOver(_wslot)) {
                        _found = _wslot.card;
                        break;
                    }
                }
            }

            if (_found == undefined) {
                for (var m = 0; m < array_length(player_monster_slots); m++) {
                    var _mslot = player_monster_slots[m];
                    if (!_mslot.visible || !_mslot.occupied || _mslot.card == undefined) continue;
                    if (SCR_Board_IsSlotMouseOver(_mslot)) {
                        _found = _mslot.card;
                        break;
                    }
                }
            }
        }
        if (_found != undefined) return _found;
    }

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand != noone && _hand.hand_Count > 0) {
        var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
        var _idx = SCR_Hand_PickCardIndex(mouse_x, mouse_y, _hand.hand_Count, _spacing, _hand.hand_Y);
        if (_idx >= 0) return _hand.hand[_idx];
    }

    return undefined;
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
        SCR_DBD_ShouldShowPreviewConditions(_card) ? SCR_DBD_GetCardConditionLines(_card) : undefined
    );
}
