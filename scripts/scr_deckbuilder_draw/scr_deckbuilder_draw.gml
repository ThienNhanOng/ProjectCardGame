/// @desc OBJ_DeckBuilder Draw — container, toolbar, deck list, hover effect

function SCR_DBD_Draw() {
    SCR_DBD_DrawContainer();
    SCR_DBD_DrawDeckInfo();
    SCR_DBD_DrawCollectionToolbar();
    SCR_DBD_DrawDeckList();
    SCR_DBD_DrawHoverPreview();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function SCR_DBD_DrawContainer() {
    // Container background
    draw_set_color(c_black);
    draw_set_alpha(0.3);
    draw_rectangle(container_x, container_y, container_x + container_w, container_y + container_h, false);
    draw_set_alpha(1);
    
    // Container border
    draw_set_color(c_white);
    draw_rectangle(container_x, container_y, container_x + container_w, container_y + container_h, true);
    
    // Label
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(container_x, container_y - 20, "Card Collection");
    
    // Page info - FIXED: Use player collection
    var _total_pages = SCR_DBD_GetCollectionPageCount(cards_per_page);
    
    draw_set_color(c_white);
    draw_set_halign(fa_right);
    draw_text(container_x + container_w - 10, container_y - 20, "Page " + string(current_page + 1) + "/" + string(_total_pages));
    draw_set_halign(fa_left);
}

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
    draw_set_color(c_ltgray);
    draw_text(room_width - 85, room_height - 48, "Esc: Menu");
    draw_set_color(c_white);
    draw_set_halign(fa_left);
}

function SCR_DBD_DrawDeckList() {
    var _layout = SCR_DBD_GetDeckListLayout();
    var _rows = SCR_DBD_BuildDeckListRows(selected_deck);

    var _scroll = SCR_DBD_ClampDeckListScroll(_layout, SCR_DBD_GetDeckListScroll(), _rows);
    SCR_DBD_SetDeckListScroll(_scroll);

    var _panel_x1 = _layout.list_x - 6;
    var _panel_y1 = 54;
    var _panel_x2 = _layout.list_x + _layout.list_w + 6;
    var _panel_y2 = _layout.list_viewport_bottom + 6;

    draw_set_color(make_color_rgb(110, 110, 115));
    draw_rectangle(_panel_x1, _panel_y1, _panel_x2, _panel_y2, true);

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_layout.list_x, 60, "=== YOUR DECK ===");

    var _total_cards = array_length(selected_deck);

    var _prev_scissor = gpu_get_scissor();
    gpu_set_scissor(floor(_layout.list_x), floor(_layout.list_y_start),
        floor(_layout.list_w), floor(_layout.list_viewport_bottom - _layout.list_y_start));

    var _card_index = 0;
    for (var i = 0; i < array_length(_rows); i++) {
        var _bounds = SCR_DBD_GetDeckListRowBounds(_layout, _rows, i, _scroll);
        if (!SCR_DBD_IsDeckListRowInViewport(_layout, _bounds)) continue;

        if (_rows[i].kind == "header") {
            _card_index = 0;
            SCR_DBD_DrawDeckListSectionHeader(_layout, _bounds, _rows[i].label, _rows[i].color);
            continue;
        }

        _card_index++;
        var _line = string(_card_index) + ". " + _rows[i].name + " x" + string(_rows[i].count);
        var _is_hovered = SCR_DBD_IsDeckListRowHovered(_bounds);
        SCR_DBD_DrawDeckListRow(_layout, _bounds, SCR_Hand_TruncateName(_line, _layout.list_w - _layout.text_pad_x * 2), _is_hovered);
    }

    gpu_set_scissor(_prev_scissor);

    if (SCR_DBD_GetDeckListMaxScroll(_layout, _rows) > 0) {
        draw_set_color(c_ltgray);
        draw_set_halign(fa_right);
        draw_set_valign(fa_top);
        draw_text(_layout.list_x + _layout.list_w, _layout.list_y_start - 2, "Scroll: wheel");
        draw_set_halign(fa_left);
    }

    draw_set_color(c_yellow);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(_layout.list_x, room_height - 50, "Total: " + string(_total_cards) + " / " + string(collection_GetDeckMaxSize()) + " cards");

    if (_total_cards < 8) {
        draw_set_color(c_red);
        draw_text(_layout.list_x, room_height - 30, "Need at least 8 cards to start!");
    }
}

function SCR_DeckHover_GetTransform(_x, _y, _w, _h, _override_hovered = undefined) {
    var _mx = mouse_x;
    var _my = mouse_y;
    var _is_hovered = (_override_hovered != undefined)
        ? _override_hovered
        : (_mx >= _x && _mx <= _x + _w && _my >= _y && _my <= _y + _h);
    
    var _draw_x = _x;
    var _draw_y = _y;
    var _draw_scale = 1.0;
    
    if (_is_hovered) {
        _draw_x = _x - 4;
        _draw_y = _y - 8;
        _draw_scale = 1.05;
    }
    
    return {
        draw_x: _draw_x,
        draw_y: _draw_y,
        draw_scale: _draw_scale,
        is_hovered: _is_hovered,
        w: _w * _draw_scale,
        h: _h * _draw_scale
    };
}

function SCR_DeckHover_DrawGlow(_draw_x, _draw_y, _w, _h, _is_hovered) {
    if (!_is_hovered) return;
    
    // Glow effect
    draw_set_color(c_yellow);
    draw_set_alpha(0.15);
    draw_rectangle(_draw_x - 8, _draw_y - 8, _draw_x + _w + 8, _draw_y + _h + 8, false);
    draw_set_alpha(1);
    
    // Border
    draw_set_color(c_yellow);
    draw_set_alpha(0.5);
    draw_rectangle(_draw_x - 3, _draw_y - 3, _draw_x + _w + 3, _draw_y + _h + 3, true);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function SCR_DeckHover_IsHovered(_x, _y, _w, _h) {
    var _mx = mouse_x;
    var _my = mouse_y;
    return (_mx >= _x && _mx <= _x + _w &&
            _my >= _y && _my <= _y + _h);
}
