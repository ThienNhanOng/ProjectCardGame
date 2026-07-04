// ===== DECK DRAW SCRIPT (with debug option) =====

function deck_GetTopCardBounds() {
    var _stack = max(0, deck_Count - 1) * 0.4;
    var _cx = deck_X + _stack;
    var _cy = deck_Y - _stack;

    return {
        cx: _cx,
        cy: _cy,
        left: _cx - deck_Width / 2,
        top: _cy - deck_Height / 2,
        right: _cx + deck_Width / 2,
        bottom: _cy + deck_Height / 2
    };
}

function deck_IsMouseOver() {
    var _box = deck_GetTopCardBounds();
    var _pad = 6;
    return (mouse_x >= _box.left - _pad && mouse_x <= _box.right + _pad &&
            mouse_y >= _box.top - _pad && mouse_y <= _box.bottom + _pad);
}

function deck_DrawHoverCount() {
    if (!deck_IsMouseOver()) return;

    var _box = deck_GetTopCardBounds();
    var _count_text = string(deck_Count);
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

function SCR_Deck_Draw(_debug = false) {
    for (var i = 0; i < deck_Count; i++) {
        var _card_id = deck[i];
        var _card_data = deck_GetCardData(_card_id);

        if (_card_data != undefined) {
            card_DrawFramedAtCenter(deck_X + (i * 0.4), deck_Y - (i * 0.4), 1, _card_data, 1);

            if (_debug) {
                draw_set_color(c_black);
                draw_set_halign(fa_center);
                draw_text(deck_X + (i * 0.4), deck_Y - (i * 0.4) + 20, _card_data.name);
                draw_set_halign(fa_left);
            }
        }
    }

    deck_DrawHoverCount();
    deck_DrawExtraDeckZone();
    draw_set_color(c_white);
}
