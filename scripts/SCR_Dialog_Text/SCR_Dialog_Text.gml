/// @desc Parse text scripts — namehero, visibility toggles, speaker keys

function dialog_ParseNameLine(_line) {
    var _lower = string_lower(string_trim(_line));
    if (string_pos("name", _lower) != 1) return undefined;

    var _body = string_trim(string_copy(_line, 5, string_length(_line)));
    var _colon = string_pos(":", _body);
    var _key = "";
    var _display = "";

    if (_colon > 1) {
        _key = string_lower(string_trim(string_copy(_body, 1, _colon - 1)));
        _display = string_trim(string_copy(_body, _colon + 1, string_length(_body)));
    } else {
        var _space = string_pos(" ", _body);
        if (_space <= 1) return undefined;
        _key = string_lower(string_trim(string_copy(_body, 1, _space - 1)));
        _display = string_trim(string_copy(_body, _space + 1, string_length(_body)));
    }

    if (_key == "" || _display == "") return undefined;
    return dialog_Name(_key, _display);
}

function dialog_ParseSideVisibleCommand(_cmd, _raw_cmd) {
    var _side = "";
    if (string_pos("left", _cmd) == 1) _side = "left";
    else if (string_pos("right", _cmd) == 1) _side = "right";
    if (_side == "") return undefined;

    var _visible = true;
    if (string_pos("hide", _cmd) > 0 || string_pos("false", _cmd) > 0 || string_pos("off", _cmd) > 0) {
        _visible = false;
    } else if (string_pos("show", _cmd) > 0 || string_pos("true", _cmd) > 0 || string_pos("on", _cmd) > 0) {
        _visible = true;
    } else {
        var _space = string_pos(" ", _raw_cmd);
        if (_space > 0) {
            var _arg = string_lower(string_trim(string_copy(_raw_cmd, _space + 1, string_length(_raw_cmd))));
            if (_arg == "false" || _arg == "off" || _arg == "hide" || _arg == "0") _visible = false;
            if (_arg == "true" || _arg == "on" || _arg == "show" || _arg == "1") _visible = true;
        }
    }

    return (_side == "left") ? dialog_LeftVisible(_visible) : dialog_RightVisible(_visible);
}

function dialog_ParseBackgroundCommand(_cmd, _raw_cmd) {
    if (_cmd == "clear bg" || _cmd == "clear background" || _cmd == "clearbg") {
        return dialog_ClearBackground();
    }

    if (_cmd == "bg hide" || _cmd == "hide bg") {
        return dialog_HideBackground();
    }
    if (_cmd == "bg show" || _cmd == "show bg") {
        return dialog_ShowBackground();
    }

    if (string_pos("bg", _cmd) != 1) return undefined;

    var _visible = true;
    var _arg = "";
    if (string_length(_raw_cmd) > 2) {
        _arg = string_trim(string_copy(_raw_cmd, 3, string_length(_raw_cmd)));
    }

    if (_arg != "") {
        var _parts = string_split(_arg, " ");
        if (array_length(_parts) >= 1) {
            var _last = string_lower(_parts[array_length(_parts) - 1]);
            if (_last == "true" || _last == "false" || _last == "show" || _last == "hide") {
                _visible = !(_last == "false" || _last == "hide");
                if (array_length(_parts) > 1) {
                    _arg = string_trim(string_copy(_arg, 1, string_length(_arg) - string_length(_last) - 1));
                } else {
                    _arg = "";
                }
            }
        }
    }

    if (_arg == "") return dialog_BackgroundVisible(_visible);
    return dialog_Background(_arg, _visible);
}

function dialog_ParseTextScript(_text) {
    var _entries = [];
    var _lines = string_split(string(_text), "\n");

    for (var i = 0; i < array_length(_lines); i++) {
        var _line = string_trim(_lines[i]);
        if (_line == "") continue;

        var _name_entry = dialog_ParseNameLine(_line);
        if (_name_entry != undefined) {
            array_push(_entries, _name_entry);
            continue;
        }

        if (string_char_at(_line, 1) == "(" && string_char_at(_line, string_length(_line)) == ")") {
            var _raw_cmd = string_trim(string_copy(_line, 2, string_length(_line) - 2));
            var _cmd = string_lower(_raw_cmd);

            if (_cmd == "clear" || _cmd == "clearcharacters" || _cmd == "clearchars") {
                array_push(_entries, dialog_ClearChars());
                continue;
            }

            var _bg = dialog_ParseBackgroundCommand(_cmd, _raw_cmd);
            if (_bg != undefined) {
                array_push(_entries, _bg);
                continue;
            }

            var _vis = dialog_ParseSideVisibleCommand(_cmd, _raw_cmd);
            if (_vis != undefined) {
                array_push(_entries, _vis);
                continue;
            }

            var _side = "";
            var _arg = "";
            var _key = "";
            var _show = true;

            if (string_pos("left", _cmd) == 1) _side = "left";
            else if (string_pos("right", _cmd) == 1) _side = "right";

            if (_side != "") {
                var _space = string_pos(" ", _raw_cmd);
                if (_space > 0) {
                    _arg = string_trim(string_copy(_raw_cmd, _space + 1, string_length(_raw_cmd)));
                    var _parts = string_split(_arg, " ");
                    if (array_length(_parts) >= 2) {
                        var _last = string_lower(_parts[array_length(_parts) - 1]);
                        if (_last == "true" || _last == "false" || _last == "show" || _last == "hide") {
                            _show = !(_last == "false" || _last == "hide");
                            _arg = string_trim(string_copy(_arg, 1, string_length(_arg) - string_length(_last) - 1));
                        }
                    }
                    var _key_space = string_pos(" ", _arg);
                    if (_key_space > 0) {
                        _key = string_lower(string_trim(string_copy(_arg, _key_space + 1, string_length(_arg))));
                        _arg = string_trim(string_copy(_arg, 1, _key_space - 1));
                    }
                }

                if (_side == "left") {
                    if (_arg == "") array_push(_entries, dialog_Left(undefined, _key, _show));
                    else array_push(_entries, dialog_Left(_arg, _key, _show));
                } else {
                    if (_arg == "") array_push(_entries, dialog_Right(undefined, _key, _show));
                    else array_push(_entries, dialog_Right(_arg, _key, _show));
                }
            }
            continue;
        }

        var _colon = string_pos(":", _line);
        if (_colon > 1) {
            var _speaker = string_trim(string_copy(_line, 1, _colon - 1));
            var _speech = string_trim(string_copy(_line, _colon + 1, string_length(_line)));
            array_push(_entries, dialog_LineKey(_speaker, _speech));
        }
    }

    return _entries;
}

function dialog_ColorFromName(_name) {
    switch (string_lower(string_trim(_name))) {
        case "blue": return c_blue;
        case "red": return c_red;
        case "green": return c_lime;
        case "yellow": return c_yellow;
        case "aqua": return c_aqua;
        case "orange": return c_orange;
        case "purple": return c_purple;
        case "gray":
        case "grey": return c_gray;
        case "white": return c_white;
        case "black": return c_black;
        default: return c_white;
    }
}

function dialog_ParseColoredText(_text) {
    var _segments = [];
    var _remaining = string(_text);

    while (string_length(_remaining) > 0) {
        var _tag_pos = string_pos("colorsentence(", string_lower(_remaining));
        if (_tag_pos <= 0) {
            if (_remaining != "") array_push(_segments, { text: _remaining, color: c_white });
            break;
        }

        if (_tag_pos > 1) {
            array_push(_segments, {
                text: string_copy(_remaining, 1, _tag_pos - 1),
                color: c_white
            });
        }

        var _after_tag = string_copy(_remaining, _tag_pos + 14, string_length(_remaining));
        var _comma = string_pos(",", _after_tag);
        if (_comma <= 0) break;

        var _color_name = string_copy(_after_tag, 1, _comma - 1);
        var _color = dialog_ColorFromName(_color_name);

        var _quote_search = string_copy(_after_tag, _comma + 1, string_length(_after_tag));
        var _q1 = string_pos("\"", _quote_search);
        if (_q1 <= 0) break;

        var _after_q1 = string_copy(_quote_search, _q1 + 1, string_length(_quote_search));
        var _q2 = string_pos("\"", _after_q1);
        if (_q2 <= 0) break;

        var _inner = string_copy(_after_q1, 1, _q2 - 1);
        array_push(_segments, { text: _inner, color: _color });

        var _after_inner = string_copy(_after_q1, _q2 + 1, string_length(_after_q1));
        var _close = string_pos(")", _after_inner);
        if (_close <= 0) break;

        _remaining = string_copy(_after_inner, _close + 1, string_length(_after_inner));
    }

    if (array_length(_segments) <= 0) {
        array_push(_segments, { text: string(_text), color: c_white });
    }

    return _segments;
}

function dialog_TruncateSegments(_segments, _max_chars) {
    if (_max_chars < 0) return _segments;

    var _out = [];
    var _left = _max_chars;

    for (var i = 0; i < array_length(_segments); i++) {
        if (_left <= 0) break;

        var _text = _segments[i].text;
        var _len = string_length(_text);
        if (_len <= _left) {
            array_push(_out, { text: _text, color: _segments[i].color });
            _left -= _len;
        } else {
            array_push(_out, {
                text: string_copy(_text, 1, _left),
                color: _segments[i].color
            });
            break;
        }
    }

    return _out;
}

function dialog_DrawColoredSegments(_x, _y, _line_h, _max_w, _segments) {
    var _cx = _x;
    var _cy = _y;

    for (var i = 0; i < array_length(_segments); i++) {
        var _seg = _segments[i];
        draw_set_color(_seg.color);

        var _chars = string_length(_seg.text);
        var _chunk = "";
        for (var c = 1; c <= _chars; c++) {
            var _next = _chunk + string_copy(_seg.text, c, 1);
            if (_cx > _x && string_width(_next) + (_cx - _x) > _max_w) {
                draw_text(_cx, _cy, _chunk);
                _chunk = string_copy(_seg.text, c, 1);
                _cx = _x;
                _cy += _line_h;
            } else {
                _chunk = _next;
            }
        }

        if (_chunk != "") {
            if (_cx > _x && string_width(_chunk) + (_cx - _x) > _max_w) {
                _cx = _x;
                _cy += _line_h;
            }
            draw_text(_cx, _cy, _chunk);
            _cx += string_width(_chunk);
        }
    }
}

function dialog_ResolveSprite(_ref) {
    if (_ref == undefined) return noone;

    if (is_string(_ref)) {
        var _name = string_trim(_ref);
        var _lower = string_lower(_name);

        if (_lower == "player" || _lower == "obj_playermarker" || _lower == "spr_dialog_player") {
            return dialog_DefaultLeftSprite();
        }
        if (_lower == "testcharacter" || _lower == "obj_testcharacter" || _lower == "spr_dialog_testcharacter") {
            return dialog_DefaultRightSprite();
        }

        var _idx = asset_get_index(_name);
        if (_idx != -1) {
            var _type = asset_get_type(_idx);
            if (_type == asset_sprite) return _idx;
            if (_type == asset_object) return object_get_sprite(_idx);
        }

        return noone;
    }

    if (is_real(_ref)) {
        if (sprite_exists(_ref)) return _ref;
        if (object_exists(_ref)) return object_get_sprite(_ref);
    }

    return noone;
}

function dialog_DefaultLeftSprite() {
    return SPR_Dialog_Player;
}

function dialog_DefaultRightSprite() {
    return SPR_Dialog_Testcharacter;
}
