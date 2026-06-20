/// @desc Battle HUD + End Turn button + hover preview

function SCR_Battle_Draw() {
    SCR_Battle_UI_Draw();

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.action_slot.occupied && _board.action_slot.card != undefined) {
        var _x = room_width - 220;
        var _y = 10;
        var _card = _board.action_slot.card;
        var _traits = battle_GetActionTraits();

        draw_set_color(c_white);
        draw_text(_x, _y, _card.name);

        for (var i = 0; i < array_length(_traits); i++) {
            var _uses_left = (i < array_length(action_trait_uses)) ? action_trait_uses[i] : 0;
            draw_text(_x, _y + 20 + i * 14,
                trait_GetDisplayText(_traits[i]) + "  x" + string(_uses_left));
        }
    }

    SCR_Battle_Targeting_Draw();

    draw_set_color(c_white);
}

function SCR_Battle_DrawOverlays() {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck != noone) {
        with (_deck) deck_ExtraDeckPicker_Draw();
    }

    battle_DrawHoverPreview();

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) conditions_summon_Draw();
    }

    draw_set_color(c_white);
}
