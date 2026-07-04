/// @desc World map dialog system — scrim, portraits, text (Space/Enter/Click to advance)

function dialog_Init() {
    if (!variable_global_exists("dialog") || !is_struct(global.dialog)) {
        global.dialog = {
            active: false,
            entries: [],
            index: 0,
            names: {},
            left_sprite: noone,
            right_sprite: noone,
            left_key: "",
            right_key: "",
            left_visible: true,
            right_visible: true,
            bg_sprite: noone,
            bg_visible: false,
            active_speaker_key: "",
            speaker: "",
            text: "",
            text_segments: [],
            typewriter_chars: 0,
            typewriter_accum: 0,
            typewriter_done: true,
            typewriter_speed: 0.45,
            on_complete: undefined,
            launch_event_id: -1,
            launch_dialog_post: undefined,
            launch_dialog_post_once: true
        };
    }

    if (!variable_struct_exists(global.dialog, "launch_event_id")) {
        global.dialog.launch_event_id = -1;
    }
    if (!variable_struct_exists(global.dialog, "launch_dialog_post")) {
        global.dialog.launch_dialog_post = undefined;
    }
    if (!variable_struct_exists(global.dialog, "launch_dialog_post_once")) {
        global.dialog.launch_dialog_post_once = true;
    }
    if (!variable_struct_exists(global.dialog, "names")) {
        global.dialog.names = {};
    }
    if (!variable_struct_exists(global.dialog, "bg_sprite")) {
        global.dialog.bg_sprite = noone;
        global.dialog.bg_visible = false;
    }
    if (!variable_struct_exists(global.dialog, "typewriter_chars")) {
        global.dialog.typewriter_chars = 0;
        global.dialog.typewriter_accum = 0;
        global.dialog.typewriter_done = true;
        global.dialog.typewriter_speed = 0.45;
    }
}

function dialog_ResetRuntimeState() {
    global.dialog.names = {};
    global.dialog.left_sprite = noone;
    global.dialog.right_sprite = noone;
    global.dialog.left_key = "";
    global.dialog.right_key = "";
    global.dialog.left_visible = true;
    global.dialog.right_visible = true;
    global.dialog.bg_sprite = noone;
    global.dialog.bg_visible = false;
    global.dialog.active_speaker_key = "";
    global.dialog.speaker = "";
    global.dialog.text = "";
    global.dialog.text_segments = [];
    dialog_TypewriterReset();
}

function dialog_TypewriterReset() {
    global.dialog.typewriter_chars = 0;
    global.dialog.typewriter_accum = 0;
    global.dialog.typewriter_done = false;
}

function dialog_GetTextCharCount(_segments) {
    var _total = 0;
    for (var i = 0; i < array_length(_segments); i++) {
        _total += string_length(_segments[i].text);
    }
    return _total;
}

function dialog_TypewriterTick() {
    if (!dialog_IsActive() || global.dialog.typewriter_done) return;

    var _total = dialog_GetTextCharCount(global.dialog.text_segments);
    if (_total <= 0) {
        global.dialog.typewriter_done = true;
        return;
    }

    global.dialog.typewriter_accum += global.dialog.typewriter_speed;
    while (global.dialog.typewriter_accum >= 1 && global.dialog.typewriter_chars < _total) {
        global.dialog.typewriter_chars++;
        global.dialog.typewriter_accum -= 1;
    }

    if (global.dialog.typewriter_chars >= _total) {
        global.dialog.typewriter_done = true;
    }
}

function dialog_TypewriterComplete() {
    global.dialog.typewriter_chars = dialog_GetTextCharCount(global.dialog.text_segments);
    global.dialog.typewriter_done = true;
    global.dialog.typewriter_accum = 0;
}

function dialog_IsActive() {
    dialog_Init();
    return global.dialog.active;
}

function dialog_ForceClose() {
    dialog_Init();
    global.dialog.active = false;
    global.dialog.entries = [];
    global.dialog.index = 0;
    global.dialog.on_complete = undefined;
    dialog_ResetRuntimeState();
}

function dialog_Start(_script_func, _on_complete = undefined) {
    dialog_ForceClose();

    if (_script_func == undefined) {
        show_debug_message("dialog_Start: expected a script function");
        if (_on_complete != undefined) _on_complete();
        return false;
    }

    var _entries = _script_func();
    if (!is_array(_entries)) {
        show_debug_message("dialog_Start: script must return an array");
        if (_on_complete != undefined) _on_complete();
        return false;
    }

    global.dialog.entries = _entries;
    global.dialog.on_complete = _on_complete;
    global.dialog.active = array_length(_entries) > 0;
    global.dialog.index = 0;

    if (global.dialog.active) {
        dialog_ShowCurrentOrAdvance();
    } else if (_on_complete != undefined) {
        _on_complete();
    }

    return global.dialog.active;
}

function dialog_Advance() {
    if (!dialog_IsActive()) return;
    global.dialog.index++;
    dialog_ShowCurrentOrAdvance();
}

function dialog_GetEntryKind(_entry) {
    if (!is_struct(_entry)) return "";
    if (variable_struct_exists(_entry, "kind")) return string(_entry.kind);
    return "";
}

function dialog_GetEntryBool(_entry, _field, _default) {
    if (!is_struct(_entry) || !variable_struct_exists(_entry, _field)) return _default;
    return _entry[$ _field];
}

function dialog_GetEntryString(_entry, _field, _default = "") {
    if (!is_struct(_entry) || !variable_struct_exists(_entry, _field)) return _default;
    return string(_entry[$ _field]);
}

function dialog_RegisterName(_key, _display) {
    var _k = string_lower(string_trim(_key));
    if (_k == "") return;
    global.dialog.names[$ _k] = string(_display);
}

function dialog_ResolveSpeakerKey(_entry) {
    var _key = dialog_GetEntryString(_entry, "speaker_key", "");
    if (_key != "") return string_lower(_key);

    var _legacy = dialog_GetEntryString(_entry, "speaker", "");
    if (_legacy == "") return "";

    return dialog_FindKeyForSpeaker(_legacy);
}

function dialog_FindKeyForSpeaker(_speaker) {
    var _lower = string_lower(string_trim(_speaker));
    if (variable_struct_exists(global.dialog.names, _lower)) return _lower;

    var _keys = variable_struct_get_names(global.dialog.names);
    for (var i = 0; i < array_length(_keys); i++) {
        var _k = _keys[i];
        if (string_lower(global.dialog.names[$ _k]) == string_lower(_speaker)) return _k;
    }

    return _lower;
}

function dialog_GetDisplayNameForKey(_key) {
    var _k = string_lower(string_trim(_key));
    if (_k == "") return "";

    if (variable_struct_exists(global.dialog.names, _k)) {
        return global.dialog.names[$ _k];
    }

    if (string_length(_k) <= 0) return _key;
    return string_upper(string_copy(_k, 1, 1)) + string_copy(_k, 2, string_length(_k) - 1);
}

function dialog_ShowCurrentOrAdvance() {
    dialog_Init();
    if (!global.dialog.active) return;

    while (global.dialog.index < array_length(global.dialog.entries)) {
        var _entry = global.dialog.entries[global.dialog.index];
        var _kind = dialog_GetEntryKind(_entry);

        switch (_kind) {
            case "name":
                dialog_RegisterName(
                    dialog_GetEntryString(_entry, "key", ""),
                    dialog_GetEntryString(_entry, "display", "")
                );
                global.dialog.index++;
                break;

            case "left":
                global.dialog.left_sprite = dialog_ValidatePortraitSprite(
                    dialog_GetEntrySprite(_entry), true);
                global.dialog.left_key = dialog_GetEntryString(_entry, "speaker_key", global.dialog.left_key);
                global.dialog.left_visible = dialog_GetEntryBool(_entry, "visible", true);
                global.dialog.index++;
                break;

            case "right":
                global.dialog.right_sprite = dialog_ValidatePortraitSprite(
                    dialog_GetEntrySprite(_entry), false);
                global.dialog.right_key = dialog_GetEntryString(_entry, "speaker_key", global.dialog.right_key);
                global.dialog.right_visible = dialog_GetEntryBool(_entry, "visible", true);
                global.dialog.index++;
                break;

            case "left_visible":
                global.dialog.left_visible = dialog_GetEntryBool(_entry, "visible", true);
                global.dialog.index++;
                break;

            case "right_visible":
                global.dialog.right_visible = dialog_GetEntryBool(_entry, "visible", true);
                global.dialog.index++;
                break;

            case "background":
                dialog_ApplyBackgroundEntry(_entry);
                global.dialog.index++;
                break;

            case "background_visible":
                global.dialog.bg_visible = dialog_GetEntryBool(_entry, "visible", true);
                global.dialog.index++;
                break;

            case "clear_background":
                global.dialog.bg_sprite = noone;
                global.dialog.bg_visible = false;
                global.dialog.index++;
                break;

            case "clear":
                global.dialog.left_sprite = noone;
                global.dialog.right_sprite = noone;
                global.dialog.left_key = "";
                global.dialog.right_key = "";
                global.dialog.left_visible = true;
                global.dialog.right_visible = true;
                global.dialog.index++;
                break;

            case "line":
                global.dialog.left_sprite = dialog_ValidatePortraitSprite(global.dialog.left_sprite, true);
                global.dialog.right_sprite = dialog_ValidatePortraitSprite(global.dialog.right_sprite, false);
                global.dialog.active_speaker_key = dialog_ResolveSpeakerKey(_entry);
                global.dialog.speaker = dialog_GetDisplayNameForKey(global.dialog.active_speaker_key);
                if (global.dialog.speaker == "" && dialog_GetEntryString(_entry, "speaker", "") != "") {
                    global.dialog.speaker = dialog_GetEntryString(_entry, "speaker", "");
                }
                global.dialog.text = dialog_GetEntryString(_entry, "text", "");
                global.dialog.text_segments = dialog_ParseColoredText(global.dialog.text);
                dialog_TypewriterReset();
                return;

            default:
                global.dialog.index++;
                break;
        }
    }

    var _callback = global.dialog.on_complete;
    dialog_ForceClose();
    if (_callback != undefined) _callback();
}

function dialog_GetEntrySprite(_entry) {
    if (!is_struct(_entry) || !variable_struct_exists(_entry, "sprite")) return noone;
    return _entry.sprite;
}

function dialog_GetPortraitAsset(_stored, _is_left) {
    if (_stored != noone && is_real(_stored) && _stored >= 0) {
        if (sprite_get_width(_stored) > 0 && sprite_get_height(_stored) > 0) {
            return _stored;
        }
    }

    var _name = _is_left ? "SPR_Dialog_Player" : "SPR_Dialog_Testcharacter";
    return asset_get_index(_name);
}

function dialog_ValidatePortraitSprite(_sprite, _is_left) {
    return dialog_GetPortraitAsset(_sprite, _is_left);
}

function dialog_ValidateBgSprite(_sprite) {
    if (_sprite == noone || _sprite == undefined) return noone;
    if (!sprite_exists(_sprite)) return noone;
    if (sprite_get_width(_sprite) <= 0 || sprite_get_height(_sprite) <= 0) return noone;
    return _sprite;
}

function dialog_GetEntryBgRef(_entry) {
    if (!is_struct(_entry)) return undefined;
    if (variable_struct_exists(_entry, "sprite_ref")) return _entry[$ "sprite_ref"];
    if (variable_struct_exists(_entry, "sprite")) return _entry[$ "sprite"];
    return undefined;
}

function dialog_ResolveBgAsset(_ref) {
    if (_ref == undefined) return noone;

    if (is_string(_ref)) {
        var _name = string_trim(_ref);
        var _idx = asset_get_index(_name);
        if (_idx != -1 && sprite_exists(_idx)) {
            return dialog_ValidateBgSprite(_idx);
        }
    }

    if (sprite_exists(_ref)) {
        return dialog_ValidateBgSprite(_ref);
    }

    var _spr = dialog_ResolveSprite(_ref);
    if (_spr != noone) {
        return dialog_ValidateBgSprite(_spr);
    }

    if (!is_string(_ref)) {
        var _as_name = string(_ref);
        if (_as_name != "" && _as_name != "undefined") {
            var _idx2 = asset_get_index(_as_name);
            if (_idx2 != -1 && sprite_exists(_idx2)) {
                return dialog_ValidateBgSprite(_idx2);
            }
        }
    }

    return noone;
}

function dialog_ApplyBackgroundEntry(_entry) {
    var _ref = dialog_GetEntryBgRef(_entry);
    global.dialog.bg_sprite = dialog_ResolveBgAsset(_ref);
    global.dialog.bg_visible = dialog_GetEntryBool(_entry, "visible", true);

    if (!sprite_exists(global.dialog.bg_sprite)) {
        show_debug_message("dialog: could not load background sprite (" + string(_ref) + ")");
    }
}

function dialog_HasBackgroundShowing() {
    return global.dialog.bg_visible && sprite_exists(global.dialog.bg_sprite);
}

function dialog_DrawTintLayer(_gw, _gh) {
    var _alpha = dialog_HasBackgroundShowing() ? 0.15 : 0.45;
    draw_set_alpha(_alpha);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
}

function dialog_DrawBackgroundLayerGui(_gw, _gh) {
    if (!dialog_HasBackgroundShowing()) return;
    draw_sprite_stretched_ext(global.dialog.bg_sprite, 0, 0, 0, _gw, _gh, c_white, 1);
}

function dialog_DrawPortraitRect(_sprite, _x1, _y1, _x2, _y2, _dim) {
    if (!sprite_exists(_sprite)) return;

    var _w = _x2 - _x1;
    var _h = _y2 - _y1;
    if (_w <= 0 || _h <= 0) return;

    var _alpha = _dim ? 0.35 : 1;
    draw_sprite_stretched_ext(_sprite, 0, _x1, _y1, _w, _h, c_white, _alpha);

    if (_dim) {
        draw_set_alpha(0.28);
        draw_set_color(c_black);
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        draw_set_alpha(1);
    }
}

function dialog_IsSideActive(_side_key) {
    if (global.dialog.active_speaker_key == "") return true;
    return (global.dialog.active_speaker_key == string_lower(_side_key) && _side_key != "");
}

function dialog_Step() {
    if (!dialog_IsActive()) return;

    dialog_TypewriterTick();

    if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter)
        || mouse_check_button_pressed(mb_left)) {
        if (!global.dialog.typewriter_done) {
            dialog_TypewriterComplete();
        } else {
            dialog_Advance();
        }
    }
}

function dialog_GetViewport() {
    var _rw = room_width;
    var _rh = room_height;
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();

    return {
        w: _gw,
        h: _gh,
        scale_x: _gw / _rw,
        scale_y: _gh / _rh
    };
}

function dialog_DrawGui() {
    if (!dialog_IsActive()) return;

    var _vp = dialog_GetViewport();
    var _sx = _vp.scale_x;
    var _sy = _vp.scale_y;
    var _gw = _vp.w;
    var _gh = _vp.h;
    var _box_h = 132 * _sy;
    var _box_y = _gh - _box_h - (18 * _sy);
    var _portrait_top = 48 * _sy;
    var _portrait_bottom = _box_y - (12 * _sy);

    var _left_spr = dialog_GetPortraitAsset(global.dialog.left_sprite, true);
    var _right_spr = dialog_GetPortraitAsset(global.dialog.right_sprite, false);

    var _has_active = (global.dialog.active_speaker_key != "");
    var _left_active = dialog_IsSideActive(global.dialog.left_key);
    var _right_active = dialog_IsSideActive(global.dialog.right_key);
    var _left_dim = _has_active && !_left_active;
    var _right_dim = _has_active && !_right_active;

    gpu_set_blendmode(bm_normal);

    dialog_DrawBackgroundLayerGui(_gw, _gh);
    dialog_DrawTintLayer(_gw, _gh);
    dialog_DrawCharactersLayerGui(_gw, _gh, _portrait_top, _portrait_bottom, _left_spr, _right_spr, _left_dim, _right_dim, _sx, _sy);
    dialog_DrawTextLayerGui(_gw, _gh, _box_y, _box_h, _sx, _sy);
}

function dialog_DrawCharactersLayerGui(_gw, _gh, _portrait_top, _portrait_bottom, _left_spr, _right_spr, _left_dim, _right_dim, _sx, _sy) {
    if (global.dialog.left_visible) {
        dialog_DrawPortraitRect(_left_spr, 24 * _sx, _portrait_top, 380 * _sx, _portrait_bottom, _left_dim);
    }
    if (global.dialog.right_visible) {
        dialog_DrawPortraitRect(_right_spr, _gw - (380 * _sx), _portrait_top, _gw - (24 * _sx), _portrait_bottom, _right_dim);
    }
}

function dialog_DrawTextLayerGui(_gw, _gh, _box_y, _box_h, _sx, _sy) {
    var _pad_x = 28 * _sx;
    var _text_x = 44 * _sx;
    var _body_y = _box_y + (36 * _sy);
    var _line_h = 20 * _sy;
    var _max_w = _gw - (88 * _sx);

    draw_set_alpha(0.9);
    draw_set_color(make_color_rgb(24, 24, 30));
    draw_rectangle(_pad_x, _box_y, _gw - _pad_x, _box_y + _box_h, false);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(105, 105, 120));
    draw_rectangle(_pad_x, _box_y, _gw - _pad_x, _box_y + _box_h, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text_transformed(_text_x, _box_y + (10 * _sy), global.dialog.speaker, _sx, _sy, 0);

    var _draw_segments = global.dialog.typewriter_done
        ? global.dialog.text_segments
        : dialog_TruncateSegments(global.dialog.text_segments, global.dialog.typewriter_chars);
    dialog_DrawColoredSegmentsGui(_text_x, _body_y, _line_h, _max_w, _draw_segments, _sx, _sy);

    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_ltgray);
    var _hint = global.dialog.typewriter_done
    draw_text_transformed(_gw / 2, _gh - (8 * _sy), _hint, _sx, _sy, 0);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function dialog_DrawColoredSegmentsGui(_x, _y, _line_h, _max_w, _segments, _sx, _sy) {
    var _cx = _x;
    var _cy = _y;

    for (var i = 0; i < array_length(_segments); i++) {
        var _seg = _segments[i];
        draw_set_color(_seg.color);

        var _chars = string_length(_seg.text);
        var _chunk = "";
        for (var c = 1; c <= _chars; c++) {
            var _next = _chunk + string_copy(_seg.text, c, 1);
            if (_cx > _x && string_width(_next) * _sx + (_cx - _x) > _max_w) {
                draw_text_transformed(_cx, _cy, _chunk, _sx, _sy, 0);
                _chunk = string_copy(_seg.text, c, 1);
                _cx = _x;
                _cy += _line_h;
            } else {
                _chunk = _next;
            }
        }

        if (_chunk != "") {
            if (_cx > _x && string_width(_chunk) * _sx + (_cx - _x) > _max_w) {
                _cx = _x;
                _cy += _line_h;
            }
            draw_text_transformed(_cx, _cy, _chunk, _sx, _sy, 0);
            _cx += string_width(_chunk) * _sx;
        }
    }
}

function dialog_TryRunPendingPost() {
    worldmap_InitGlobals();

    if (!variable_struct_exists(global.worldmap, "pending_dialog_post")) return;
    var _func = global.worldmap.pending_dialog_post;
    global.worldmap.pending_dialog_post = undefined;

    if (_func != undefined) {
        dialog_Start(_func);
    }
}

function dialog_Draw() {
    dialog_DrawGui();
}
