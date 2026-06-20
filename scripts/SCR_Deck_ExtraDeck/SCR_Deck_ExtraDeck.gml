/// @desc Extra deck zone display + horizontal picker in battle

function deck_GetExtraDeckZoneBounds() {
    var _stack = max(0, extra_deck_Count - 1) * 0.4;
    var _cx = extra_deck_X + _stack;
    var _cy = extra_deck_Y - _stack;

    return {
        cx: _cx,
        cy: _cy,
        left: _cx - extra_deck_Width / 2,
        top: _cy - extra_deck_Height / 2,
        right: _cx + extra_deck_Width / 2,
        bottom: _cy + extra_deck_Height / 2
    };
}

function deck_IsMouseOverExtraDeck() {
    var _box = deck_GetExtraDeckZoneBounds();
    var _pad = 8;
    return (mouse_x >= _box.left - _pad && mouse_x <= _box.right + _pad &&
            mouse_y >= _box.top - _pad && mouse_y <= _box.bottom + _pad);
}

function deck_ExtraDeck_CanInteract() {
    if (battle_IsPlayerDefeated()) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return true;

    with (_bm) {
        if (!battle_IsPlayerPhase()) return false;
        if (battle_IsTargeting()) return false;
        if (conditions_summon_IsActive()) return false;
    }
    return true;
}

function deck_ExtraDeckPicker_IsOpen() {
    return extra_deck_picker_open;
}

function deck_ExtraDeckPicker_Open() {
    extra_deck_picker_open = true;
    extra_deck_picker_scroll = 0;
}

function deck_ExtraDeckPicker_Close() {
    extra_deck_picker_open = false;
    extra_deck_picker_scroll = 0;
}

function deck_ExtraDeckPicker_GetLayout() {
    var _field_w = sprite_get_width(SPR_Field);
    var _field_h = sprite_get_height(SPR_Field);
    var _panel_w = min(520, _field_w - 40);
    var _panel_h = 180;
    var _left = (_field_w - _panel_w) / 2;
    var _top = (_field_h - _panel_h) / 2;

    return {
        left: _left,
        top: _top,
        right: _left + _panel_w,
        bottom: _top + _panel_h,
        card_w: 73,
        card_h: 101,
        gap: 14,
        pad_x: 18,
        pad_y: 18,
        card_offset_y: 14
    };
}

function deck_ExtraDeckPicker_GetCardTop(_layout) {
    return _layout.top + _layout.pad_y + _layout.card_offset_y;
}

function deck_ExtraDeckPicker_GetContentWidth(_layout) {
    if (extra_deck_Count <= 0) return 0;
    return extra_deck_Count * (_layout.card_w + _layout.gap) - _layout.gap;
}

function deck_ExtraDeckPicker_GetMaxScroll(_layout) {
    var _view_w = (_layout.right - _layout.left) - _layout.pad_x * 2;
    var _content_w = deck_ExtraDeckPicker_GetContentWidth(_layout);
    return max(0, _content_w - _view_w);
}

function deck_ExtraDeckPicker_GetCardBounds(_index, _layout) {
    var _x = _layout.left + _layout.pad_x + _index * (_layout.card_w + _layout.gap) - extra_deck_picker_scroll;
    var _y = deck_ExtraDeckPicker_GetCardTop(_layout);
    return {
        left: _x,
        top: _y,
        right: _x + _layout.card_w,
        bottom: _y + _layout.card_h
    };
}

function deck_ExtraDeckPicker_PickIndexAt(_mx, _my) {
    var _layout = deck_ExtraDeckPicker_GetLayout();
    var _clip_left = _layout.left + _layout.pad_x;
    var _clip_right = _layout.right - _layout.pad_x;
    var _clip_top = deck_ExtraDeckPicker_GetCardTop(_layout);
    var _clip_bottom = _layout.bottom - _layout.pad_y;

    if (_mx < _clip_left || _mx > _clip_right || _my < _clip_top || _my > _clip_bottom) {
        return -1;
    }

    for (var i = 0; i < extra_deck_Count; i++) {
        var _box = deck_ExtraDeckPicker_GetCardBounds(i, _layout);
        if (_mx >= _box.left && _mx <= _box.right && _my >= _box.top && _my <= _box.bottom) {
            return i;
        }
    }
    return -1;
}

function deck_RemoveExtraCardAt(_index) {
    if (_index < 0 || _index >= extra_deck_Count) return -1;

    var _card_id = extra_deck[_index];
    for (var i = _index; i < extra_deck_Count - 1; i++) {
        extra_deck[i] = extra_deck[i + 1];
    }
    extra_deck[extra_deck_Count - 1] = 0;
    extra_deck_Count--;
    return _card_id;
}

function deck_ExtraDeckPicker_SelectCard(_index) {
    if (_index < 0 || _index >= extra_deck_Count) return false;
    return conditions_TryBeginFromExtraDeck(_index);
}

function deck_DrawExtraDeckHoverCount() {
    if (!deck_IsMouseOverExtraDeck()) return;

    var _box = deck_GetExtraDeckZoneBounds();
    var _count_text = string(extra_deck_Count);
    var _scale = 2.5;

    draw_set_alpha(0.35);
    draw_set_color(c_black);
    draw_rectangle(_box.left, _box.top, _box.right, _box.bottom, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text_transformed(_box.cx, _box.cy, _count_text, _scale, _scale, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function deck_DrawExtraDeckZone() {
    if (extra_deck_Count <= 0) {
        draw_sprite(SPR_Cardback, 0, extra_deck_X, extra_deck_Y);
    } else {
        for (var i = 0; i < extra_deck_Count; i++) {
            var _card_id = extra_deck[i];
            var _card_data = deck_GetCardData(_card_id);
            if (_card_data == undefined) continue;

            var _spr = SPR_Monsterplaceholder;
            if (_card_data.type == "weapon") _spr = SPR_Weaponplaceholder;
            else if (_card_data.type == "action") _spr = SPR_Actionplaceholder;

            draw_sprite(_spr, 0, extra_deck_X + (i * 0.4), extra_deck_Y - (i * 0.4));
        }
    }

    deck_DrawExtraDeckHoverCount();
}

function deck_ExtraDeckPicker_Draw() {
    if (!extra_deck_picker_open) return;

    var _layout = deck_ExtraDeckPicker_GetLayout();

    draw_set_alpha(0.55);
    draw_set_color(c_black);
    draw_rectangle(0, 0, sprite_get_width(SPR_Field), sprite_get_height(SPR_Field), false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(35, 35, 45));
    draw_rectangle(_layout.left, _layout.top, _layout.right, _layout.bottom, false);
    draw_set_color(c_white);
    draw_rectangle(_layout.left, _layout.top, _layout.right, _layout.bottom, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text((_layout.left + _layout.right) / 2, _layout.top + 4, "Extra Deck");
    draw_set_halign(fa_left);

    var _clip_left = _layout.left + _layout.pad_x;
    var _clip_right = _layout.right - _layout.pad_x;
    var _clip_top = deck_ExtraDeckPicker_GetCardTop(_layout);
    var _clip_bottom = _layout.bottom - _layout.pad_y;

    if (extra_deck_Count <= 0) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_ltgray);
        draw_text((_layout.left + _layout.right) / 2, (_clip_top + _clip_bottom) / 2, "No cards in extra deck");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(c_white);
        return;
    }

    var _prev_scissor = gpu_get_scissor();
    gpu_set_scissor(floor(_clip_left - 10), floor(_clip_top - 12),
        floor(_clip_right - _clip_left + 20), floor(_clip_bottom - _clip_top + 24));

    for (var i = 0; i < extra_deck_Count; i++) {
        var _box = deck_ExtraDeckPicker_GetCardBounds(i, _layout);
        if (_box.right < _clip_left || _box.left > _clip_right) continue;

        var _card_data = deck_GetCardData(extra_deck[i]);
        if (_card_data == undefined) continue;

        SCR_ExtraDeck_DrawCard(_box.left, _box.top, _layout.card_w, _layout.card_h, _card_data);
    }

    gpu_set_scissor(_prev_scissor);

    var _max_scroll = deck_ExtraDeckPicker_GetMaxScroll(_layout);
    if (_max_scroll > 0) {
        draw_set_color(c_ltgray);
        draw_text(_layout.left + 8, _layout.bottom - 20,
            "Scroll: wheel / arrows  |  Click card to summon");
    } else {
        draw_set_color(c_ltgray);
        draw_text(_layout.left + 8, _layout.bottom - 20, "Click a card to summon");
    }

    draw_set_color(c_white);
}

function deck_ExtraDeck_Step() {
    if (extra_deck_picker_open) {
        if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
            deck_ExtraDeckPicker_Close();
            return;
        }

        var _wheel = mouse_wheel_up() - mouse_wheel_down();
        if (_wheel != 0) {
            var _layout = deck_ExtraDeckPicker_GetLayout();
            var _max_scroll = deck_ExtraDeckPicker_GetMaxScroll(_layout);
            extra_deck_picker_scroll = clamp(extra_deck_picker_scroll - _wheel * 28, 0, _max_scroll);
        }

        if (keyboard_check_pressed(vk_left)) {
            var _layout_l = deck_ExtraDeckPicker_GetLayout();
            extra_deck_picker_scroll = max(0, extra_deck_picker_scroll - 40);
        }
        if (keyboard_check_pressed(vk_right)) {
            var _layout_r = deck_ExtraDeckPicker_GetLayout();
            extra_deck_picker_scroll = min(deck_ExtraDeckPicker_GetMaxScroll(_layout_r), extra_deck_picker_scroll + 40);
        }

        if (mouse_check_button_pressed(mb_left)) {
            var _layout = deck_ExtraDeckPicker_GetLayout();
            if (mouse_x >= _layout.left && mouse_x <= _layout.right &&
                mouse_y >= _layout.top && mouse_y <= _layout.bottom) {
                var _picked = deck_ExtraDeckPicker_PickIndexAt(mouse_x, mouse_y);
                if (_picked >= 0) {
                    deck_ExtraDeckPicker_SelectCard(_picked);
                }
            } else {
                deck_ExtraDeckPicker_Close();
            }
        }
        return;
    }

    if (!deck_ExtraDeck_CanInteract()) return;
    if (!mouse_check_button_pressed(mb_left)) return;
    if (!deck_IsMouseOverExtraDeck()) return;

    deck_ExtraDeckPicker_Open();
}
