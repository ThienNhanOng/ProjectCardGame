/// @desc Home screen (Room_home, OBJ_HomeMenu): Play / Continue, Quick Save, Quick Load, Save and Exit, Exit,
/// the slot picker behind Play, and the account switcher. Saving itself lives in scr_save_system.
///
///   Play         no game running: pick a slot (load it, or start a new game in an empty slot 2-4)
///   Continue     a game is running (you came here with Esc / Menu from the map): back to it
///   Quick Save   the running game -> the slot you are playing (first empty manual slot when playing the autosave)
///   Quick Load   the newest save of this account
///   Save and Exit   Quick Save, then close the game
///   Exit         close the game without saving

#macro HOME_BTN_W 300
#macro HOME_BTN_H 46
#macro HOME_BTN_GAP 12
#macro HOME_SLOT_W 620
#macro HOME_SLOT_H 62

function SCR_HomeMenu_Create() {
    save_Init();
    home_panel = "main";   // "main" or "slots"
}

// ---------------------------------------------------------------------------
// Layout (GUI coordinates)
// ---------------------------------------------------------------------------

/// The main buttons: { id, label, enabled, x1, y1, x2, y2 }
function home_GetButtons() {
    var _s = save_State();
    var _saves = save_AccountSaves();
    var _any = _saves && save_AnySave();
    var _cx = display_get_gui_width() * 0.5;
    var _top = 270;
    var _defs = [
        { id: "play", label: _s.in_game ? "Continue" : "Play", enabled: true },
        { id: "quick_save", label: "Quick Save", enabled: _s.in_game && _saves },
        { id: "quick_load", label: "Quick Load", enabled: _any || !_saves },
        { id: "save_exit", label: "Save and Exit", enabled: _s.in_game && _saves },
        { id: "exit", label: "Exit", enabled: true }
    ];
    for (var i = 0; i < array_length(_defs); i++) {
        var _y = _top + i * (HOME_BTN_H + HOME_BTN_GAP);
        _defs[i].x1 = _cx - HOME_BTN_W / 2;
        _defs[i].y1 = _y;
        _defs[i].x2 = _cx + HOME_BTN_W / 2;
        _defs[i].y2 = _y + HOME_BTN_H;
    }
    return _defs;
}

function home_GetAccountButton() {
    var _cx = display_get_gui_width() * 0.5;
    return { x1: _cx + 70, y1: 196, x2: _cx + 170, y2: 226 };
}

/// Slot rows for the Play panel: { slot, summary, enabled, x1, y1, x2, y2 } plus a Back button
function home_GetSlotRows() {
    var _cx = display_get_gui_width() * 0.5;
    var _top = 230;
    var _rows = [];
    for (var i = 1; i <= SAVE_SLOT_COUNT; i++) {
        var _sum = save_SlotSummary(i);
        var _y = _top + (i - 1) * (HOME_SLOT_H + 10);
        array_push(_rows, { slot: i, summary: _sum, enabled: _sum.exists || i != SAVE_SLOT_AUTO,
            x1: _cx - HOME_SLOT_W / 2, y1: _y, x2: _cx + HOME_SLOT_W / 2, y2: _y + HOME_SLOT_H });
    }
    return _rows;
}

function home_GetBackButton() {
    var _cx = display_get_gui_width() * 0.5;
    var _y = 230 + SAVE_SLOT_COUNT * (HOME_SLOT_H + 10) + 10;
    return { x1: _cx - 80, y1: _y, x2: _cx + 80, y2: _y + 40 };
}

function home_MouseIn(_r) {
    return point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _r.x1, _r.y1, _r.x2, _r.y2);
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

function SCR_HomeMenu_Step() {
    var _s = save_State();

    if (keyboard_check_pressed(vk_escape)) {
        if (home_panel == "slots") home_panel = "main";
        else if (_s.in_game) save_Resume();
        return;
    }
    if (!mouse_check_button_pressed(mb_left)) return;

    if (home_panel == "slots") {
        if (home_MouseIn(home_GetBackButton())) { home_panel = "main"; return; }
        var _rows = home_GetSlotRows();
        for (var r = 0; r < array_length(_rows); r++) {
            if (!_rows[r].enabled || !home_MouseIn(_rows[r])) continue;
            if (_rows[r].summary.exists) save_LoadSlot(_rows[r].slot);
            else save_StartNewGame(_rows[r].slot);
            return;
        }
        return;
    }

    if (home_MouseIn(home_GetAccountButton())) {
        save_SetAccount(save_NextAccount());
        return;
    }

    var _buttons = home_GetButtons();
    for (var i = 0; i < array_length(_buttons); i++) {
        var _b = _buttons[i];
        if (!_b.enabled || !home_MouseIn(_b)) continue;
        home_Press(_b.id);
        return;
    }
}

/// What a main button does (also used by tests)
function home_Press(_id) {
    var _s = save_State();
    switch (_id) {
        case "play":
            if (_s.in_game) { save_Resume(); break; }
            if (!save_AccountSaves()) { save_StartNewGame(-1); break; }   // the no-save test account always starts over
            home_panel = "slots";
            break;
        case "quick_save": save_QuickSave(); break;
        case "quick_load": save_QuickLoad(); break;
        case "save_exit": save_SaveAndExit(); break;
        case "exit": game_end(); break;
    }
}

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

function home_DrawButton(_r, _label, _enabled, _sub = "") {
    var _hover = _enabled && home_MouseIn(_r);
    draw_set_alpha(_enabled ? 1 : 0.4);
    draw_set_color(_hover ? make_color_rgb(78, 60, 42) : make_color_rgb(46, 35, 26));
    draw_roundrect_ext(_r.x1, _r.y1, _r.x2, _r.y2, 10, 10, false);
    draw_set_color(_hover ? make_color_rgb(255, 214, 110) : make_color_rgb(201, 162, 74));
    draw_roundrect_ext(_r.x1, _r.y1, _r.x2, _r.y2, 10, 10, true);
    draw_roundrect_ext(_r.x1 + 1, _r.y1 + 1, _r.x2 - 1, _r.y2 - 1, 10, 10, true);
    draw_set_color(make_color_rgb(239, 227, 196));
    if (_sub == "") {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text((_r.x1 + _r.x2) / 2, (_r.y1 + _r.y2) / 2, _label);
    } else {
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_text(_r.x1 + 16, _r.y1 + 10, _label);
        draw_set_color(make_color_rgb(190, 180, 160));
        draw_text(_r.x1 + 16, _r.y1 + 34, _sub);
    }
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function SCR_HomeMenu_DrawGUI() {
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _cx = _gw * 0.5;
    var _s = save_State();

    // the grasslands battlefield, darkened
    var _bg = asset_get_index(BATTLE_DEFAULT_BACKGROUND);
    if (_bg != -1) draw_sprite_stretched(_bg, 0, 0, 0, _gw, _gh);
    draw_set_alpha(0.55);
    draw_set_color(make_color_rgb(14, 11, 8));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    // title
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(14, 11, 8));
    draw_text_transformed(_cx + 3, 113, "Card Game", 4, 4, 0);
    draw_set_color(make_color_rgb(255, 214, 110));
    draw_text_transformed(_cx, 110, "Card Game", 4, 4, 0);

    // account
    draw_set_halign(fa_right);
    draw_set_color(make_color_rgb(239, 227, 196));
    var _acc = "Account: " + _s.account;
    if (!save_AccountSaves()) _acc += "  (never saves)";
    draw_text(_cx + 60, 211, _acc);
    home_DrawButton(home_GetAccountButton(), "Switch", true);

    if (home_panel == "slots") {
        var _rows = home_GetSlotRows();
        for (var r = 0; r < array_length(_rows); r++) {
            var _row = _rows[r];
            var _label = _row.summary.title + (_row.summary.exists ? "   - Load" : ((_row.slot == SAVE_SLOT_AUTO) ? "" : "   - New Game"));
            home_DrawButton(_row, _label, _row.enabled, _row.summary.detail);
        }
        home_DrawButton(home_GetBackButton(), "Back", true);
    } else {
        var _buttons = home_GetButtons();
        for (var i = 0; i < array_length(_buttons); i++) {
            home_DrawButton(_buttons[i], _buttons[i].label, _buttons[i].enabled);
        }
        if (_s.in_game && _s.slot > 0) {
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_color(make_color_rgb(190, 180, 160));
            draw_text(_cx, _buttons[array_length(_buttons) - 1].y2 + 14, "Playing slot " + string(_s.slot) + "   (slot 1 autosaves on every map)");
        }
    }

    // last message (saved / loaded / ...)
    if (_s.message != "" && current_time - _s.message_time < SAVE_MESSAGE_MS) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(14, 11, 8));
        draw_text(_cx + 1, _gh - 59, _s.message);
        draw_set_color(make_color_rgb(150, 230, 150));
        draw_text(_cx, _gh - 60, _s.message);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
