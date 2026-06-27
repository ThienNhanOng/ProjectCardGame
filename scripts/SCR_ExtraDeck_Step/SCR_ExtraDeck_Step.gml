/// @description Handle mouse wheel + keyboard pagination for the extra deck strip
function SCR_ExtraDeck_Step() {
    if (mouse_x >= extra_x && mouse_x <= extra_x + extra_w &&
        mouse_y >= extra_y && mouse_y <= extra_y + extra_h) {
        
        var _new_page = extra_current_page;
        
        if (mouse_wheel_up())   _new_page--;
        if (mouse_wheel_down()) _new_page++;
        
        if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
            _new_page++;
        }
        if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
            _new_page--;
        }
        
        _new_page = clamp(_new_page, 0, extra_total_pages - 1);
        
        if (_new_page != extra_current_page) {
            extra_current_page = _new_page;
        }
    }
}
