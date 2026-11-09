function SCR_Board_Draw() {
    SCR_Board_DrawEmptyZones();     // only while dragging a monster card
    SCR_Board_DrawPlacedCards();
}

/// Empty monster spots light up only while you drag a card that can go there
function SCR_Board_DrawEmptyZones() {
    if (!is_dragging || !SCR_Board_IsMonsterCard(drag_card)) return;
    var _target = SCR_Board_GetDropTarget(mouse_x, mouse_y, drag_card);
    var _pulse = 0.55 + 0.35 * sin(current_time / 180);
    var _brass = make_color_rgb(201, 162, 74);
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _s = player_monster_slots[i];
        if (!_s.visible || _s.locked || _s.occupied) continue;
        var _over = (_target != undefined && _target.monster == i);
        draw_set_alpha(_over ? 0.35 : 0.14);
        draw_set_color(_brass);
        draw_roundrect_ext(_s.x, _s.y, _s.x + _s.w, _s.y + _s.h, 12, 12, false);
        draw_set_alpha(_over ? 1 : _pulse);
        draw_set_color(make_color_rgb(239, 227, 196));
        SCR_Board_DrawDashedRect(_s.x, _s.y, _s.x + _s.w, _s.y + _s.h, _over ? 4 : 3);
        draw_set_alpha(1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        battle_DrawOutlinedText(_s.x + _s.w / 2, _s.y + _s.h / 2, "Place here", make_color_rgb(239, 227, 196));
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

/// Marching dashed outline
function SCR_Board_DrawDashedRect(_x1, _y1, _x2, _y2, _w) {
    var _dash = 9;
    var _gap = 7;
    var _off = (current_time / 40) mod (_dash + _gap);
    var _edges = [[_x1, _y1, _x2, _y1], [_x2, _y1, _x2, _y2], [_x2, _y2, _x1, _y2], [_x1, _y2, _x1, _y1]];
    for (var e = 0; e < 4; e++) {
        var _ex = _edges[e];
        var _len = point_distance(_ex[0], _ex[1], _ex[2], _ex[3]);
        var _dx = (_ex[2] - _ex[0]) / _len;
        var _dy = (_ex[3] - _ex[1]) / _len;
        for (var d = _off - (_dash + _gap); d < _len; d += _dash + _gap) {
            var _a = max(0, d);
            var _b = min(_len, d + _dash);
            if (_b <= _a) continue;
            draw_line_width(_ex[0] + _dx * _a, _ex[1] + _dy * _a, _ex[0] + _dx * _b, _ex[1] + _dy * _b, _w);
        }
    }
}

function SCR_Board_IsSlotMouseOver(_slot) {
    var _card_w = _slot.w;
    var _card_h = _slot.h;
    var _left   = _slot.x;
    var _top    = _slot.y;
    var _right  = _slot.x + _card_w;
    var _bottom = _slot.y + _card_h;
    
    return (mouse_x >= _left && mouse_x <= _right &&
            mouse_y >= _top  && mouse_y <= _bottom);
}

function SCR_Board_DrawPlayerMonsterOverlay(_slot, _card_w, _card_h) {
    if (_slot == undefined || !_slot.visible || !_slot.occupied || _slot.card == undefined) return;
    if (battlefx_IsArriving(_slot.card)) return;   // health bar etc. appear with the unit

    battle_EnsureCardHealth(_slot.card);

    var _cx = _slot.x + _card_w / 2;
    var _bar_y = _slot.y + _card_h + 5;   // health bar under the card
    monster_DrawHealthBar(_slot.x + 4, _bar_y, _card_w - 8, 9,
        battlefx_DisplayHealth(_slot.card), _slot.card.max_health);

    var _attack_gain = card_GetAttackBuff(_slot.card);
    card_DrawAttackGainBadge(_slot.x, _slot.y, _card_w, _card_h, _attack_gain);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    if (card_IsSpiritType(_slot.card)) {
        var _strike = card_GetBoardAttackDisplay(_slot.card, _slot.index);
        if (_strike > 0) battle_DrawOutlinedText(_cx, _bar_y + 12, "ATK " + string(_strike), make_color_rgb(255, 170, 150));
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) {
            if (!battle_CanColumnAttack(_slot.index) && _slot.index < array_length(weapon_attacks_used)
                && battle_GetColumnAttackUsesLeft(_slot.index) <= 0) {
                draw_set_halign(fa_center);
                battle_DrawOutlinedText(_cx, _bar_y + 12, "used", c_ltgray);
            }
        }
    }

    var _pstatus = status_GetDisplayText(_slot.card);
    if (_pstatus != "") battle_DrawOutlinedText(_cx, _bar_y + 26, _pstatus, c_orange);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function SCR_Board_DrawPlacedCards() {
    var _brass = make_color_rgb(201, 162, 74);
    var _gold = make_color_rgb(255, 214, 110);
    var _drag_item = is_dragging && drag_card != undefined && !SCR_Board_IsMonsterCard(drag_card);
    var _target = _drag_item ? SCR_Board_GetDropTarget(mouse_x, mouse_y, drag_card) : undefined;
    var _bm = instance_find(OBJ_BattleManager, 0);

    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _slot = player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;

        // still on its way in: only its shadow (the smoke reveals it)
        if (battlefx_IsArriving(_slot.card)) {
            var _arr_spr = card_GetFieldSprite(_slot.card);
            var _arr_feet = _slot.y + _slot.h - 10;
            if (_arr_spr != -1) {
                battlefx_DrawArrivalShadow(_slot.card, _arr_spr, floor(current_time / 1000 * MONSTER_ANIM_IDLE_FPS) mod sprite_get_number(_arr_spr),
                    _slot.x + _slot.w / 2, _arr_feet, MONSTER_ANIM_SCALE, MONSTER_ANIM_SCALE);
            } else {
                var _art = card_GetArtSprite(_slot.card);
                var _as = _slot.h / sprite_get_height(_art);
                battlefx_DrawArrivalShadow(_slot.card, _art, 0, _slot.x + _slot.w / 2, _arr_feet, _as, _as, -sprite_get_height(_art) * _as / 2);
            }
            continue;
        }

        var _can_take = _drag_item && SCR_Board_CanDropOnMonster(i, drag_card);
        var _drop_over = (_target != undefined && _target.monster == i);
        var _hover = !is_dragging && SCR_Board_IsSlotMouseOver(_slot);
        var _grow = _drop_over ? 1.16 : (_hover ? 1.08 : 1);
        var _cx = _slot.x + _slot.w / 2;
        var _cy = _slot.y + _slot.h / 2;
        var _w = _slot.w * _grow;
        var _h = _slot.h * _grow;
        var _x = _cx - _w / 2;
        var _y = _cy - _h / 2;

        // ground shadow (characters get a pedestal instead)
        draw_set_alpha(card_GetFieldSprite(_slot.card) != -1 ? 0 : 0.35);
        draw_set_color(c_black);
        draw_ellipse(_cx - 50, _slot.y + _slot.h - 4, _cx + 54, _slot.y + _slot.h + 14, false);
        draw_set_alpha(1);

        // monsters that can take the dragged weapon / action pulse; the one under it lights up strongly
        if (_can_take) {
            draw_set_color(_drop_over ? _gold : _brass);
            draw_set_alpha(_drop_over ? 1 : 0.5 + 0.4 * sin(current_time / 160));
            var _t = _drop_over ? 7 : 4;
            for (var k = 0; k < _t; k++) draw_roundrect_ext(_x - 9 + k, _y - 9 + k, _x + _w + 9 - k, _y + _h + 9 - k, 14, 14, true);
            if (_drop_over) {
                draw_set_alpha(0.25);
                for (var g = 1; g <= 4; g++) draw_roundrect_ext(_x - 9 - g * 3, _y - 9 - g * 3, _x + _w + 9 + g * 3, _y + _h + 9 + g * 3, 16, 16, true);
            }
            draw_set_alpha(1);
        }

        // ready to strike with its weapon
        var _ready = false;
        if (_bm != noone) with (_bm) _ready = battle_CanColumnAttack(i);
        if (_ready && !_drag_item) {
            draw_set_color(make_color_rgb(242, 201, 76));
            draw_set_alpha(0.6 + 0.3 * sin(current_time / 200));
            for (var r = 0; r < 3; r++) draw_roundrect_ext(_x - 4 + r, _y - 4 + r, _x + _w + 4 - r, _y + _h + 4 - r, 10, 10, true);
            draw_set_alpha(1);
        }

        // the character itself (facing right, on a pedestal), or the card when it has no field sprite
        var _unit_spr = card_GetFieldSprite(_slot.card);
        var _name_y = _y - 3;
        if (_unit_spr != -1) {
            var _feet = _slot.y + _slot.h - 10;
            var _sc = MONSTER_ANIM_SCALE * _grow;
            battle_DrawPedestal(_cx, _feet, 1, 0.9);
            var _frame = floor(current_time / 1000 * MONSTER_ANIM_IDLE_FPS + i * 5) mod sprite_get_number(_unit_spr);
            draw_sprite_ext(_unit_spr, _frame, _cx, _feet, _sc, _sc, 0, c_white, battlefx_BlinkAlpha(_slot.card));
            // cultivated monsters keep their gold stars on the field
            if (card_GetRarity(_slot.card) >= 1) card_DrawCultivatedStars(_cx, _feet - 46 * _sc, 96 * _sc, 104 * _sc, _slot.card, 1);
            _name_y = _feet - 96 * _sc;
        } else {
            card_DrawFramedInRect(_x, _y, _w, _h, _slot.card, battlefx_BlinkAlpha(_slot.card));
        }

        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        battle_DrawOutlinedText(_cx, _name_y, SCR_Hand_TruncateName(_slot.card.name, 120), c_white);

        // weapon chip on the card's bottom-left corner
        var _wslot = player_weapon_slots[i];
        if (_wslot.occupied && _wslot.card != undefined) SCR_Board_DrawWeaponChip(_x + 10, _y + _h - 12, _wslot.card);

        if (_drop_over) {
            draw_set_alpha(0.55);
            draw_set_color(make_color_rgb(18, 14, 11));
            draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 6, 6, false);
            draw_set_alpha(1);
            draw_set_valign(fa_middle);
            var _verb = (drag_card.type == "weapon") ? "EQUIP" : "USE";
            draw_set_color(make_color_rgb(14, 11, 8));
            draw_text_transformed(_cx + 2, _cy - 8 + 2, _verb, 2, 2, 0);
            draw_set_color(_gold);
            draw_text_transformed(_cx, _cy - 8, _verb, 2, 2, 0);
            battle_DrawOutlinedText(_cx, _cy + 22, SCR_Hand_TruncateName(drag_card.name, _w - 6), c_white);
        }
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }

    for (var m = 0; m < array_length(player_monster_slots); m++) {
        SCR_Board_DrawPlayerMonsterOverlay(player_monster_slots[m], player_monster_slots[m].w, player_monster_slots[m].h);
    }

    // the action card while it resolves
    if (action_slot.occupied && action_slot.card != undefined) {
        var _hovered = !is_dragging && SCR_Board_IsSlotMouseOver(action_slot);
        card_DrawFramedAtCenter(action_slot.x + action_slot.w / 2, action_slot.y + action_slot.h / 2, _hovered ? 1.2 : 1, action_slot.card, 1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        battle_DrawOutlinedText(action_slot.x + action_slot.w / 2, action_slot.y - 3, "Playing", make_color_rgb(239, 227, 196));
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

/// Small round weapon badge: the weapon's art and its attack bonus
function SCR_Board_DrawWeaponChip(_x, _y, _weapon) {
    draw_set_color(make_color_rgb(239, 227, 196));
    draw_circle(_x, _y, 15, false);
    draw_set_color(make_color_rgb(201, 162, 74));
    draw_circle(_x, _y, 15, true);
    draw_circle(_x, _y, 14, true);
    var _art = card_GetArtSprite(_weapon);
    var _s = 26 / max(1, sprite_get_height(_art));
    draw_sprite_ext(_art, 0, _x - sprite_get_width(_art) * _s / 2 + sprite_get_xoffset(_art) * _s,
        _y - sprite_get_height(_art) * _s / 2 + sprite_get_yoffset(_art) * _s, _s, _s, 0, c_white, 1);
    var _amt = weapon_GetAttackAmount(_weapon);
    if (_amt > 0) {
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        battle_DrawOutlinedText(_x + 17, _y, "+" + string(_amt), make_color_rgb(255, 214, 110));
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
