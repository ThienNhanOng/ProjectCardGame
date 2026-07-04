function SCR_DBD_GetCollectionToolbarLayout() {
    var _btn_w = 88;
    var _btn_h = 28;
    var _gap = 8;
    var _y = container_y + container_h + 38;

    return {
        y: _y,
        btn_w: _btn_w,
        btn_h: _btn_h,
        gap: _gap,
        monster: { x: container_x, y: _y, w: _btn_w, h: _btn_h },
        weapon: { x: container_x + (_btn_w + _gap), y: _y, w: _btn_w, h: _btn_h },
        action: { x: container_x + (_btn_w + _gap) * 2, y: _y, w: _btn_w, h: _btn_h },
        search: {
            x: container_x + (_btn_w + _gap) * 3 + 16,
            y: _y,
            w: 340,
            h: _btn_h
        }
    };
}

function SCR_DBD_IsToolbarRectHovered(_rect) {
    return (mouse_x >= _rect.x && mouse_x < _rect.x + _rect.w
        && mouse_y >= _rect.y && mouse_y < _rect.y + _rect.h);
}

function SCR_DBD_DrawToolbarButton(_rect, _label, _active, _hover) {
    draw_set_alpha(_active ? 0.85 : (_hover ? 0.65 : 0.45));
    draw_set_color(_active ? make_color_rgb(70, 110, 70) : make_color_rgb(55, 55, 60));
    draw_rectangle(_rect.x, _rect.y, _rect.x + _rect.w, _rect.y + _rect.h, false);
    draw_set_alpha(1);

    draw_set_color(_active ? c_lime : (_hover ? c_yellow : make_color_rgb(110, 110, 115)));
    draw_rectangle(_rect.x, _rect.y, _rect.x + _rect.w, _rect.y + _rect.h, true);

    draw_set_color(_active ? c_white : c_ltgray);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_rect.x + (_rect.w * 0.5), _rect.y + (_rect.h * 0.5), _label);
}

function SCR_DBD_DrawCollectionToolbar() {
    var _layout = SCR_DBD_GetCollectionToolbarLayout();

    SCR_DBD_DrawToolbarButton(_layout.monster, "Monster",
        filter_type == "monster", SCR_DBD_IsToolbarRectHovered(_layout.monster));
    SCR_DBD_DrawToolbarButton(_layout.weapon, "Weapon",
        filter_type == "weapon", SCR_DBD_IsToolbarRectHovered(_layout.weapon));
    SCR_DBD_DrawToolbarButton(_layout.action, "Action",
        filter_type == "action", SCR_DBD_IsToolbarRectHovered(_layout.action));

    var _search = _layout.search;
    var _search_hover = SCR_DBD_IsToolbarRectHovered(_search);

    draw_set_alpha(search_focused ? 0.85 : (_search_hover ? 0.65 : 0.45));
    draw_set_color(make_color_rgb(40, 40, 45));
    draw_rectangle(_search.x, _search.y, _search.x + _search.w, _search.y + _search.h, false);
    draw_set_alpha(1);

    draw_set_color(search_focused ? c_aqua : (_search_hover ? c_yellow : make_color_rgb(110, 110, 115)));
    draw_rectangle(_search.x, _search.y, _search.x + _search.w, _search.y + _search.h, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    if (search_text != "") {
        draw_set_color(c_white);
        draw_text(_search.x + 8, _search.y + (_search.h * 0.5), search_text + (search_focused ? "|" : ""));
    } else {
        draw_set_color(c_gray);
        draw_text(_search.x + 8, _search.y + (_search.h * 0.5),
            search_focused ? "|" : "Search name or tag...");
    }
}

function SCR_DBD_DrawDeckInfo() {
    var _deck_size = array_length(selected_deck);
    var _info_y = container_y + container_h + 10;
    var _label_gap = 16;

    var _spirit_owned = 0;
    for (var i = 0; i < array_length(global.player_collection); i++) {
        var _card = global.player_collection[i];
        if (_card.type == "spirit") {
            _spirit_owned += _card.owned;
        }
    }

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _deck_text = "Deck: " + string(_deck_size) + " / " + string(collection_GetDeckMaxSize());
    draw_text(container_x, _info_y, _deck_text);

    var _sep_x = container_x + string_width(_deck_text) + _label_gap;
    draw_text(_sep_x, _info_y, "|");

    var _spirit_x = _sep_x + string_width("|") + _label_gap;
    draw_text(_spirit_x, _info_y, "Spirit: " + string(_spirit_owned));

    if (_deck_size >= 8) {
        draw_set_color(c_green);
    } else {
        draw_set_color(c_red);
    }
    draw_rectangle(room_width - 150, room_height - 100, room_width - 20, room_height - 60, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(room_width - 85, room_height - 88, "READY");
    draw_set_halign(fa_left);
}
