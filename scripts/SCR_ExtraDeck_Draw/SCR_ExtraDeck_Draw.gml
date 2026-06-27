/// @description Draw the extra deck container, label, and horizontal spirit copies
function SCR_ExtraDeck_Draw() {
    draw_set_color(c_black);
    draw_set_alpha(0.3);
    draw_rectangle(extra_x, extra_y, extra_x + extra_w, extra_y + extra_h, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_rectangle(extra_x, extra_y, extra_x + extra_w, extra_y + extra_h, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(extra_x, extra_y - 40, "Spirit Owned");

    var _ids = SCR_ExtraDeck_GetCopyIds();
    SCR_ExtraDeck_ClampFocus(array_length(_ids));

    draw_set_halign(fa_right);
    draw_text(extra_x + extra_w, extra_y - 20,
        array_length(_ids) > 0
            ? string(extra_focus_index + 1) + "/" + string(array_length(_ids)) + "  A/D"
            : "0 copies");
    draw_set_halign(fa_left);

    if (array_length(_ids) <= 0) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_ltgray);
        draw_text(extra_x + extra_w / 2, extra_y + extra_h / 2, "No spirits owned");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(c_white);
        return;
    }

    var _view = SCR_ExtraDeck_GetViewInner();
    var _prev_scissor = gpu_get_scissor();
    gpu_set_scissor(floor(_view.left - 2), floor(_view.top - 2),
        floor(_view.right - _view.left + 4), floor(_view.bottom - _view.top + 4));

    for (var i = 0; i < array_length(_ids); i++) {
        var _bounds = SCR_ExtraDeck_GetCardBounds(i, extra_scroll);
        if (_bounds.x + _bounds.w < _view.left || _bounds.x > _view.right) continue;

        var _card_data = deck_GetCardData(_ids[i]);
        if (_card_data == undefined) continue;

        SCR_ExtraDeck_DrawCard(_bounds.x, _bounds.y, _bounds.w, _bounds.h, _card_data, i == extra_focus_index);
    }

    gpu_set_scissor(_prev_scissor);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
