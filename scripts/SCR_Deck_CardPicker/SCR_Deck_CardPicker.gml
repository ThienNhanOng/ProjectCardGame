/// @desc Shared horizontal scroll picker (extra deck summon + tag search add)



function deck_AnyPickerOpen() {

    return extra_deck_picker_open || tag_picker_open;

}



function deck_ScrollPicker_GetLayout() {

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



function deck_ScrollPicker_GetCardTop(_layout) {

    return _layout.top + _layout.pad_y + _layout.card_offset_y;

}



function deck_ScrollPicker_GetContentWidth(_card_ids) {

    var _layout = deck_ScrollPicker_GetLayout();

    var _count = array_length(_card_ids);

    if (_count <= 0) return 0;

    return _count * (_layout.card_w + _layout.gap) - _layout.gap;

}



function deck_ScrollPicker_GetMaxScroll(_card_ids) {

    var _layout = deck_ScrollPicker_GetLayout();

    var _view_w = (_layout.right - _layout.left) - _layout.pad_x * 2;

    var _content_w = deck_ScrollPicker_GetContentWidth(_card_ids);

    return max(0, _content_w - _view_w);

}



function deck_ScrollPicker_GetCardBounds(_index, _card_ids, _scroll) {

    var _layout = deck_ScrollPicker_GetLayout();

    var _x = _layout.left + _layout.pad_x + _index * (_layout.card_w + _layout.gap) - _scroll;

    var _y = deck_ScrollPicker_GetCardTop(_layout);

    return {

        left: _x,

        top: _y,

        right: _x + _layout.card_w,

        bottom: _y + _layout.card_h

    };

}



function deck_ScrollPicker_ClampFocus(_card_ids, _focus) {

    var _count = array_length(_card_ids);

    if (_count <= 0) return 0;

    return clamp(_focus, 0, _count - 1);

}



function deck_ScrollPicker_ScrollToFocus(_card_ids, _scroll, _focus) {

    var _layout = deck_ScrollPicker_GetLayout();

    var _clip_left = _layout.left + _layout.pad_x;

    var _clip_right = _layout.right - _layout.pad_x;

    var _box = deck_ScrollPicker_GetCardBounds(_focus, _card_ids, _scroll);

    var _max_scroll = deck_ScrollPicker_GetMaxScroll(_card_ids);



    if (_box.left < _clip_left) {

        _scroll = max(0, _scroll - (_clip_left - _box.left));

    } else if (_box.right > _clip_right) {

        _scroll = min(_max_scroll, _scroll + (_box.right - _clip_right));

    }

    return clamp(_scroll, 0, _max_scroll);

}



function deck_ScrollPicker_GetPreviewCard(_card_ids, _scroll, _focus) {
    if (array_length(_card_ids) <= 0) return undefined;

    var _idx = deck_ScrollPicker_PickIndexAt(mouse_x, mouse_y, _card_ids, _scroll);
    if (_idx < 0) _idx = deck_ScrollPicker_ClampFocus(_card_ids, _focus);
    if (_idx < 0 || _idx >= array_length(_card_ids)) return undefined;

    return deck_GetCardData(_card_ids[_idx]);
}

function deck_ScrollPicker_PickIndexAt(_mx, _my, _card_ids, _scroll) {

    var _layout = deck_ScrollPicker_GetLayout();

    var _clip_left = _layout.left + _layout.pad_x;

    var _clip_right = _layout.right - _layout.pad_x;

    var _clip_top = deck_ScrollPicker_GetCardTop(_layout);

    var _clip_bottom = _layout.bottom - _layout.pad_y;



    if (_mx < _clip_left || _mx > _clip_right || _my < _clip_top || _my > _clip_bottom) {

        return -1;

    }



    for (var i = 0; i < array_length(_card_ids); i++) {

        var _box = deck_ScrollPicker_GetCardBounds(i, _card_ids, _scroll);

        if (_mx >= _box.left && _mx <= _box.right && _my >= _box.top && _my <= _box.bottom) {

            return i;

        }

    }

    return -1;

}



function deck_ScrollPicker_ApplyScrollInput(_card_ids, _scroll, _focus) {

    _focus = deck_ScrollPicker_ClampFocus(_card_ids, _focus);



    if (keyboard_check_pressed(ord("A"))) {

        _focus = max(0, _focus - 1);

        _scroll = deck_ScrollPicker_ScrollToFocus(_card_ids, _scroll, _focus);

        return { scroll: _scroll, focus: _focus };

    }

    if (keyboard_check_pressed(ord("D"))) {

        _focus = min(array_length(_card_ids) - 1, _focus + 1);

        _scroll = deck_ScrollPicker_ScrollToFocus(_card_ids, _scroll, _focus);

        return { scroll: _scroll, focus: _focus };

    }



    var _wheel = mouse_wheel_up() - mouse_wheel_down();

    if (_wheel != 0) {

        var _max_scroll = deck_ScrollPicker_GetMaxScroll(_card_ids);

        _scroll = clamp(_scroll - _wheel * 28, 0, _max_scroll);

        return { scroll: _scroll, focus: _focus };

    }



    if (keyboard_check_pressed(vk_left)) {

        _scroll = max(0, _scroll - 40);

    }

    if (keyboard_check_pressed(vk_right)) {

        _scroll = min(deck_ScrollPicker_GetMaxScroll(_card_ids), _scroll + 40);

    }



    return { scroll: _scroll, focus: _focus };

}



function deck_ScrollPicker_DrawPanel(_title, _card_ids, _scroll, _focus, _empty_text, _footer_hint, _keep_cards_in_box = false) {

    var _layout = deck_ScrollPicker_GetLayout();

    _focus = deck_ScrollPicker_ClampFocus(_card_ids, _focus);



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

    draw_text((_layout.left + _layout.right) / 2, _layout.top + 4, _title);

    draw_set_halign(fa_left);



    var _clip_left = _layout.left + _layout.pad_x;

    var _clip_right = _layout.right - _layout.pad_x;

    var _clip_top = deck_ScrollPicker_GetCardTop(_layout);

    var _clip_bottom = _layout.bottom - _layout.pad_y;



    if (array_length(_card_ids) <= 0) {

        draw_set_halign(fa_center);

        draw_set_valign(fa_middle);

        draw_set_color(c_ltgray);

        draw_text((_layout.left + _layout.right) / 2, (_clip_top + _clip_bottom) / 2, _empty_text);

        draw_set_halign(fa_left);

        draw_set_valign(fa_top);

        draw_set_color(c_white);

        return;

    }



    draw_set_halign(fa_right);

    draw_text(_layout.right - 8, _layout.top + 4,

        string(_focus + 1) + "/" + string(array_length(_card_ids)));

    draw_set_halign(fa_left);



    var _prev_scissor = gpu_get_scissor();
    gpu_set_scissor(floor(_clip_left), floor(_clip_top),
        floor(_clip_right - _clip_left), floor(_clip_bottom - _clip_top));



    for (var i = 0; i < array_length(_card_ids); i++) {

        var _box = deck_ScrollPicker_GetCardBounds(i, _card_ids, _scroll);

        if (_box.right < _clip_left || _box.left > _clip_right) continue;



        var _card_data = deck_GetCardData(_card_ids[i]);

        if (_card_data == undefined) continue;



        SCR_ExtraDeck_DrawCard(_box.left, _box.top, _layout.card_w, _layout.card_h, _card_data, i == _focus, _keep_cards_in_box);

    }



    gpu_set_scissor(_prev_scissor);



    draw_set_color(c_ltgray);

    if (deck_ScrollPicker_GetMaxScroll(_card_ids) > 0) {

        draw_text(_layout.left + 8, _layout.bottom - 20,

            "A/D focus | wheel scroll  |  " + _footer_hint);

    } else {

        draw_text(_layout.left + 8, _layout.bottom - 20, "A/D focus  |  " + _footer_hint);

    }



    draw_set_color(c_white);

}



function deck_AllPickers_Draw() {

    if (tag_picker_open) {

        deck_ScrollPicker_DrawPanel(tag_picker_title, tag_picker_card_ids, tag_picker_scroll,

            tag_picker_focus, "No cards match those tags", tag_picker_footer_hint);

    }



    if (extra_deck_picker_open) {

        var _ids = [];

        for (var i = 0; i < extra_deck_Count; i++) {

            array_push(_ids, extraDeck_GetCardId(extra_deck[i]));

        }

        deck_ScrollPicker_DrawPanel("Extra Deck", _ids, extra_deck_picker_scroll,

            extra_deck_picker_focus, "No cards in extra deck", "Click card to summon");

    }

}


