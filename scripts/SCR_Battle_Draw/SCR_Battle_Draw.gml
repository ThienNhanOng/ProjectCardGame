/// @desc Battle HUD — action card abilities from JSON

function SCR_Battle_Draw() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || !_board.action_slot.occupied || _board.action_slot.card == undefined) {
        SCR_Battle_Targeting_Draw();
        return;
    }

    var _x = room_width - 220;
    var _y = 10;
    var _card = _board.action_slot.card;
    var _traits = battle_GetActionTraits();

    draw_set_color(c_white);
    draw_text(_x, _y, "Turn " + string(turn_number));
    draw_text(_x, _y + 16, _card.name);

    for (var i = 0; i < array_length(_traits); i++) {
        var _uses_left = (i < array_length(action_trait_uses)) ? action_trait_uses[i] : 0;
        draw_text(_x, _y + 36 + i * 14,
            trait_GetDisplayText(_traits[i]) + "  x" + string(_uses_left));
    }

    SCR_Battle_Targeting_Draw();
}
