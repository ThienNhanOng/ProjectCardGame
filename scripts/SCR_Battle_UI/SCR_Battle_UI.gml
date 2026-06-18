/// @desc End Turn button + turn HUD helpers

function battle_GetEndTurnButtonRect() {
    var _deck = instance_find(OBJ_Deck, 0);
    var _left = 600;

    if (_deck != noone) {
        _left = _deck.deck_X + 52;
    }

    return {
        left: _left,
        top: 585,
        right: _left + 120,
        bottom: 633
    };
}

function battle_IsEndTurnButtonHovered() {
    var _rect = battle_GetEndTurnButtonRect();
    return (mouse_x >= _rect.left && mouse_x <= _rect.right &&
            mouse_y >= _rect.top && mouse_y <= _rect.bottom);
}

function battle_HandleEndTurnButton() {
    if (!mouse_check_button_pressed(mb_left)) return;
    if (!battle_IsEndTurnButtonHovered()) return;
    battle_EndTurn();
}

function SCR_Battle_UI_Draw() {
    var _rect = battle_GetEndTurnButtonRect();
    var _hover = battle_IsEndTurnButtonHovered();
    var _enabled = battle_CanEndTurn();

    var _phase_text = battle_IsPlayerPhase() ? "Your turn" : "Enemy turn";
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(_rect.left, _rect.top - 32, "Turn " + string(turn_number) + " — " + _phase_text);

    if (battle_IsEnemyPhase()) {
        draw_set_color(c_ltgray);
        draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text((_rect.left + _rect.right) / 2, (_rect.top + _rect.bottom) / 2, "Enemy...");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        return;
    }

    if (_enabled && _hover) draw_set_color(c_yellow);
    else if (_enabled) draw_set_color(c_white);
    else draw_set_color(c_gray);

    draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);

    if (_enabled && _hover) {
        draw_set_color(c_orange);
        draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_enabled ? c_black : c_dkgray);
    draw_text((_rect.left + _rect.right) / 2, (_rect.top + _rect.bottom) / 2, "End Turn");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
