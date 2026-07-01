/// @desc Extra deck zone display + horizontal picker in battle

function deck_GetExtraDeckZoneBounds() {
    var _visible = max(1, min(extra_deck_Count, 6));
    var _spacing = 10;
    var _stack_w = max(extra_deck_Width, (_visible - 1) * _spacing + extra_deck_Width * 0.6);
    var _cx = extra_deck_X;
    var _cy = extra_deck_Y;

    return {
        cx: _cx,
        cy: _cy,
        left: _cx - _stack_w / 2,
        top: _cy - extra_deck_Height / 2,
        right: _cx + _stack_w / 2,
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
    if (tag_picker_open) deck_TagPicker_Close();
    extra_deck_picker_open = true;
    extra_deck_picker_scroll = 0;
    extra_deck_picker_focus = 0;
}

function deck_ExtraDeckPicker_Close() {
    extra_deck_picker_open = false;
    extra_deck_picker_scroll = 0;
    extra_deck_picker_focus = 0;
}

function deck_ExtraDeckPicker_GetExtraDeckIds() {
    var _ids = [];
    for (var i = 0; i < extra_deck_Count; i++) {
        array_push(_ids, extraDeck_GetCardId(extra_deck[i]));
    }
    return _ids;
}

function deck_ExtraDeckPicker_PickIndexAt(_mx, _my) {
    return deck_ScrollPicker_PickIndexAt(_mx, _my, deck_ExtraDeckPicker_GetExtraDeckIds(), extra_deck_picker_scroll);
}

function deck_RemoveExtraCardAt(_index, _permanent = true) {
    if (_index < 0 || _index >= extra_deck_Count) return undefined;

    var _entry = extra_deck[_index];
    for (var i = _index; i < extra_deck_Count - 1; i++) {
        extra_deck[i] = extra_deck[i + 1];
    }
    extra_deck[extra_deck_Count - 1] = 0;
    extra_deck_Count--;

    if (_permanent) {
        battle_PermanentlyRemoveSpiritEntry(_entry);
    }

    return _entry;
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
        var _visible = min(extra_deck_Count, 6);
        var _spacing = 10;
        var _total_w = (_visible - 1) * _spacing;
        var _start_x = extra_deck_X - _total_w / 2;

        for (var i = 0; i < _visible; i++) {
            var _card_id = extra_deck[i];
            _card_id = extraDeck_GetCardId(_card_id);
            var _card_data = deck_GetCardData(_card_id);
            if (_card_data == undefined) continue;

            var _spr = SPR_Monsterplaceholder;
            if (_card_data.type == "weapon") _spr = SPR_Weaponplaceholder;
            else if (_card_data.type == "action") _spr = SPR_Actionplaceholder;

            draw_sprite(_spr, 0, _start_x + i * _spacing, extra_deck_Y);
        }

        if (extra_deck_Count > _visible) {
            draw_set_halign(fa_center);
            draw_set_valign(fa_bottom);
            draw_set_color(c_yellow);
            draw_text(extra_deck_X, extra_deck_Y + extra_deck_Height / 2 + 4,
                "+" + string(extra_deck_Count - _visible));
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_color(c_white);
        }
    }

    deck_DrawExtraDeckHoverCount();
}

function deck_ExtraDeckPicker_Draw() {
    deck_AllPickers_Draw();
}

function deck_ExtraDeck_Step() {
    if (tag_picker_open) {
        deck_TagPicker_Step();
        return;
    }

    if (extra_deck_picker_open) {
        if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
            deck_ExtraDeckPicker_Close();
            return;
        }

        var _ids = deck_ExtraDeckPicker_GetExtraDeckIds();
        var _input = deck_ScrollPicker_ApplyScrollInput(_ids, extra_deck_picker_scroll, extra_deck_picker_focus);
        extra_deck_picker_scroll = _input.scroll;
        extra_deck_picker_focus = _input.focus;

        if (mouse_check_button_pressed(mb_left)) {
            var _layout = deck_ScrollPicker_GetLayout();
            if (mouse_x >= _layout.left && mouse_x <= _layout.right &&
                mouse_y >= _layout.top && mouse_y <= _layout.bottom) {
                var _picked = deck_ExtraDeckPicker_PickIndexAt(mouse_x, mouse_y);
                if (_picked >= 0) {
                    extra_deck_picker_focus = _picked;
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
