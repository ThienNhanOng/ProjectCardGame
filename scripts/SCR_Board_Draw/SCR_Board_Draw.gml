function SCR_Board_Draw() {
    SCR_Board_DrawEmptyZones();     // only while dragging a monster card
    SCR_Board_DrawPlacedCards();
}

/// Empty monster spots light up while you drag a card that can go there, or while a summon waits for a spot
function SCR_Board_DrawEmptyZones() {
    var _summoning = battle_IsPickingSummonSpot();
    if (!_summoning && (!is_dragging || !SCR_Board_IsMonsterCard(drag_card))) return;
    var _over_spot = -1;
    if (_summoning) {
        _over_spot = SCR_Board_MonsterSlotAt(mouse_x, mouse_y, false);
    } else {
        var _target = SCR_Board_GetDropTarget(mouse_x, mouse_y, drag_card);
        if (_target != undefined) _over_spot = _target.monster;
    }
    var _label = _summoning ? "Summon here" : "Place here";
    var _pulse = 0.55 + 0.35 * sin(current_time / 180);
    var _brass = make_color_rgb(201, 162, 74);
    for (var i = 0; i < array_length(player_monster_slots); i++) {
        var _s = player_monster_slots[i];
        if (!_s.visible || _s.locked || _s.occupied) continue;
        var _over = (_over_spot == i);
        draw_set_alpha(_over ? 0.35 : 0.14);
        draw_set_color(_brass);
        draw_roundrect_ext(_s.x, _s.y, _s.x + _s.w, _s.y + _s.h, 12, 12, false);
        draw_set_alpha(_over ? 1 : _pulse);
        draw_set_color(make_color_rgb(239, 227, 196));
        SCR_Board_DrawDashedRect(_s.x, _s.y, _s.x + _s.w, _s.y + _s.h, _over ? 4 : 3);
        draw_set_alpha(1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        battle_DrawOutlinedText(_s.x + _s.w / 2, _s.y + _s.h / 2, _label, make_color_rgb(239, 227, 196));
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

/// Health bar, ATK, status under one of your units (they move with it while it runs up to attack).
/// _ghost: draw this card instead (a unit already gone whose fatal blow hasn't landed yet)
function SCR_Board_DrawPlayerMonsterOverlay(_slot, _card_w, _card_h, _ghost = undefined) {
    if (_slot == undefined || !_slot.visible) return;
    var _card = (_ghost != undefined) ? _ghost : _slot.card;
    if (_card == undefined || (_ghost == undefined && !_slot.occupied)) return;
    if (battlefx_IsArriving(_card)) return;   // health bar etc. appear with the unit
    var _off = battlefx_UnitOffset(_card);
    var _sx = _slot.x + _off.x;
    var _sy = _slot.y + _off.y;

    battle_EnsureCardHealth(_card);

    var _cx = _sx + _card_w / 2;
    var _bar_y = _sy + _card_h + 5;   // health bar under the card
    monster_DrawHealthBar(_sx + 4, _bar_y, _card_w - 8, 9,
        battlefx_DisplayHealth(_card), _card.max_health);

    var _attack_gain = card_GetAttackBuff(_card);
    card_DrawAttackGainBadge(_sx, _sy, _card_w, _card_h, _attack_gain);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    // ATK (right of the health bar): the full damage of its next attack — character attack + weapon + buffs,
    // plus the action card's damage while it is using (or about to use) an attack action card.
    // Shown once the column can strike (weapon / spirit) or an action card is making it attack.
    var _parts = battle_GetColumnStrikeParts(_slot.index);
    var _action_atk = (_ghost == undefined) ? battle_GetPreviewActionAttack(_slot.index) : -1;
    if (_ghost == undefined && (_parts.armed || _action_atk >= 0)) {
        var _strike = (_action_atk >= 0) ? battle_ColumnActionStrikeTotal(_parts, _action_atk) : battle_ColumnSingleStrikeTotal(_parts);
        if (_strike > 0) {
            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            battle_DrawOutlinedText(_sx + _card_w + 6, _bar_y + 5, "ATK " + string(_strike),
                (_action_atk >= 0) ? make_color_rgb(255, 214, 110) : make_color_rgb(255, 170, 150));
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
        }
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone && _ghost == undefined) {
        with (_bm) {
            if (!battle_CanColumnAttack(_slot.index) && _slot.index < array_length(weapon_attacks_used)
                && battle_GetColumnAttackUsesLeft(_slot.index) <= 0) {
                draw_set_halign(fa_center);
                battle_DrawOutlinedText(_cx, _bar_y + 12, "used", c_ltgray);
            }
        }
    }

    var _pstatus = status_GetDisplayText(_card);
    if (_pstatus != "") battle_DrawOutlinedText(_cx, _bar_y + 26, _pstatus, c_orange);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

/// Your units far to near (they can overlap). Health bars etc. go over every body; the unit under the
/// mouse is drawn last, whole and a bit bigger, so it pops out while the others stay behind.
function SCR_Board_DrawPlacedCards() {
    var _hovered = is_dragging ? -1 : unit_GetHoveredSlot(SIDE_PLAYER);
    var _order = unit_GetDepthOrder(SIDE_PLAYER, _hovered);

    for (var o = 0; o < array_length(_order); o++) {
        if (_order[o] != _hovered) SCR_Board_DrawPlayerUnit(_order[o], false);
    }
    for (var m = 0; m < array_length(_order); m++) {
        var _ms = player_monster_slots[_order[m]];
        if (_order[m] != _hovered) SCR_Board_DrawPlayerMonsterOverlay(_ms, _ms.w, _ms.h);
    }
    if (_hovered >= 0) {
        var _hs = player_monster_slots[_hovered];
        SCR_Board_DrawPlayerUnit(_hovered, true);
        SCR_Board_DrawPlayerMonsterOverlay(_hs, _hs.w, _hs.h);
    }

    SCR_Board_DrawActionSlotCard();
}

/// One of your units: its card (or character on a pedestal), glows, name and chips. _hover: under the mouse.
/// It is drawn where it is right now (it runs up to its target when it attacks: battlefx_UnitOffset).
/// _ghost: draw this card instead (a unit already gone whose fatal blow hasn't landed yet)
function SCR_Board_DrawPlayerUnit(i, _hover, _ghost = undefined) {
    var _brass = make_color_rgb(201, 162, 74);
    var _gold = make_color_rgb(255, 214, 110);
    var _drag_item = is_dragging && drag_card != undefined && !SCR_Board_IsMonsterCard(drag_card);
    var _target = _drag_item ? SCR_Board_GetDropTarget(mouse_x, mouse_y, drag_card) : undefined;
    var _bm = instance_find(OBJ_BattleManager, 0);

    var _slot = player_monster_slots[i];
    var _card = (_ghost != undefined) ? _ghost : _slot.card;
    if (!_slot.visible || _card == undefined || (_ghost == undefined && !_slot.occupied)) return;
    if (_ghost != undefined) { _drag_item = false; _target = undefined; }

    // still on its way in: only its shadow (the smoke reveals it)
    if (battlefx_IsArriving(_card)) {
        var _arr_spr = card_GetFieldSprite(_card);
        var _arr_feet = _slot.y + _slot.h - 10;
        if (_arr_spr != -1) {
            battlefx_DrawArrivalShadow(_card, _arr_spr, floor(current_time / 1000 * MONSTER_ANIM_IDLE_FPS) mod sprite_get_number(_arr_spr),
                _slot.x + _slot.w / 2, _arr_feet, MONSTER_ANIM_SCALE, MONSTER_ANIM_SCALE);
        } else {
            var _art = card_GetArtSprite(_card);
            var _as = _slot.h / sprite_get_height(_art);
            battlefx_DrawArrivalShadow(_card, _art, 0, _slot.x + _slot.w / 2, _arr_feet, _as, _as, -sprite_get_height(_art) * _as / 2);
        }
        return;
    }

    var _can_take = _drag_item && SCR_Board_CanDropOnMonster(i, drag_card);
    var _drop_over = (_target != undefined && _target.monster == i);
    var _grow = _drop_over ? 1.16 : (_hover ? UNIT_HOVER_SCALE : 1);
    var _off = battlefx_UnitOffset(_card);
    var _sx = _slot.x + _off.x;
    var _sy = _slot.y + _off.y;
    var _cx = _sx + _slot.w / 2;
    var _cy = _sy + _slot.h / 2;
    var _w = _slot.w * _grow;
    var _h = _slot.h * _grow;
    var _x = _cx - _w / 2;
    var _y = _cy - _h / 2;

    // ground shadow (characters get a pedestal instead)
    draw_set_alpha(card_GetFieldSprite(_card) != -1 ? 0 : 0.35);
    draw_set_color(c_black);
    draw_ellipse(_cx - 50, _sy + _slot.h - 4, _cx + 54, _sy + _slot.h + 14, false);
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
    if (_bm != noone && _ghost == undefined) with (_bm) _ready = battle_CanColumnAttack(i);
    if (_ready && !_drag_item) {
        draw_set_color(make_color_rgb(242, 201, 76));
        draw_set_alpha(0.6 + 0.3 * sin(current_time / 200));
        for (var r = 0; r < 3; r++) draw_roundrect_ext(_x - 4 + r, _y - 4 + r, _x + _w + 4 - r, _y + _h + 4 - r, 10, 10, true);
        draw_set_alpha(1);
    }

    // the character itself (facing right, on a pedestal), or the card when it has no field sprite
    var _unit_spr = card_GetFieldSprite(_card);
    var _name_y = _y - 3;
    if (_unit_spr != -1) {
        var _feet = _sy + _slot.h - 10;
        var _sc = MONSTER_ANIM_SCALE * _grow;
        battle_DrawPedestal(_cx, _feet, 1, 0.9);
        var _frame = floor(current_time / 1000 * MONSTER_ANIM_IDLE_FPS + i * 5) mod sprite_get_number(_unit_spr);
        draw_sprite_ext(_unit_spr, _frame, _cx, _feet, _sc, _sc, 0, c_white, battlefx_BlinkAlpha(_card));
        // cultivated monsters keep their gold stars on the field
        if (card_GetRarity(_card) >= 1) card_DrawCultivatedStars(_cx, _feet - 46 * _sc, 96 * _sc, 104 * _sc, _card, 1);
        _name_y = _feet - 96 * _sc;
    } else {
        card_DrawFramedInRect(_x, _y, _w, _h, _card, battlefx_BlinkAlpha(_card));
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    battle_DrawOutlinedText(_cx, _name_y, SCR_Hand_TruncateName(_card.name, 120), c_white);

    // weapon chip on the card's bottom-left corner, frontline shield on the bottom-right
    var _wslot = player_weapon_slots[i];
    if (_wslot.occupied && _wslot.card != undefined) SCR_Board_DrawWeaponChip(_x + 10, _y + _h - 12, _wslot.card);
    if (card_HasKeyword(_card, "frontline")) SCR_Board_DrawFrontlineChip(_x + _w - 10, _y + _h - 12);

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

/// The action card while it resolves (shown above the battlefield)
function SCR_Board_DrawActionSlotCard() {
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

/// Shield chip: this monster has the frontline keyword (its side's back row takes no damage while it stands)
function SCR_Board_DrawFrontlineChip(_x, _y) {
    draw_set_color(make_color_rgb(239, 227, 196));
    draw_circle(_x, _y, 13, false);
    draw_set_color(make_color_rgb(201, 162, 74));
    draw_circle(_x, _y, 13, true);
    draw_circle(_x, _y, 12, true);
    // shield: flat top, pointed bottom
    draw_set_color(make_color_rgb(70, 120, 190));
    draw_rectangle(_x - 6, _y - 7, _x + 6, _y + 1, false);
    draw_triangle(_x - 6, _y + 1, _x + 6, _y + 1, _x, _y + 8, false);
    draw_set_color(make_color_rgb(200, 225, 255));
    draw_line(_x, _y - 6, _x, _y + 6);
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
