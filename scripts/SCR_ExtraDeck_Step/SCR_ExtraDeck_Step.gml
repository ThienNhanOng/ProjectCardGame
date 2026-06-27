/// @description Horizontal scroll + A/D focus for the spirit extra deck strip
function SCR_ExtraDeck_Step() {
    var _ids = SCR_ExtraDeck_GetCopyIds();
    var _count = array_length(_ids);
    SCR_ExtraDeck_ClampFocus(_count);

    var _in_box = (mouse_x >= extra_x && mouse_x <= extra_x + extra_w
        && mouse_y >= extra_y && mouse_y <= extra_y + extra_h);

    if (_count <= 0) return;

    if (_in_box) {
        var _wheel = mouse_wheel_up() - mouse_wheel_down();
        if (_wheel != 0) {
            extra_scroll = clamp(extra_scroll - _wheel * 28, 0, SCR_ExtraDeck_GetMaxScroll(_count));
        }
    }

    if (keyboard_check_pressed(ord("A"))) {
        extra_focus_index = max(0, extra_focus_index - 1);
        extra_scroll = SCR_ExtraDeck_ScrollToShowIndex(extra_focus_index, extra_scroll, _count);
    }
    if (keyboard_check_pressed(ord("D"))) {
        extra_focus_index = min(_count - 1, extra_focus_index + 1);
        extra_scroll = SCR_ExtraDeck_ScrollToShowIndex(extra_focus_index, extra_scroll, _count);
    }

    if (_in_box && mouse_check_button_pressed(mb_left)) {
        var _picked = SCR_ExtraDeck_PickIndexAt(mouse_x, mouse_y, extra_scroll, _count);
        if (_picked >= 0) {
            extra_focus_index = _picked;
            extra_scroll = SCR_ExtraDeck_ScrollToShowIndex(extra_focus_index, extra_scroll, _count);
        }
    }
}
