/// @desc Enemy slot drawing, hitboxes and hover

function monster_DrawHealthBar(_x, _y, _w, _h, _current, _max) {
    var _ratio = (_max > 0) ? clamp(_current / _max, 0, 1) : 0;

    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    draw_set_color(c_lime);
    draw_rectangle(_x, _y, _x + _w * _ratio, _y + _h, false);

    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_x + _w / 2, _y + _h / 2, string(round(_current)) + "/" + string(_max));
    draw_set_valign(fa_top);
}

/// The enemy itself (or its arrival shadow). _pop: it is under the mouse — drawn bigger
function monster_DrawBody(_slot, _monster, _pop = false) {
    // still on its way in: only its shadow (the smoke reveals it)
    if (battlefx_IsArriving(_monster)) {
        var _set = monsterAnim_GetSpriteSet(_monster);
        var _feet = battle_LayoutEnemyFeet(_slot.index);
        if (_set != undefined) {
            battlefx_DrawArrivalShadow(_monster, _set.idle, floor(current_time / 1000 * MONSTER_ANIM_IDLE_FPS) mod sprite_get_number(_set.idle),
                _feet.x, _feet.y, MONSTER_ANIM_SCALE * MONSTER_FACING, MONSTER_ANIM_SCALE);
        } else {
            var _st = SCR_Monster_ResolveSprite(_monster);
            battlefx_DrawArrivalShadow(_monster, _st, 0, _feet.x, _feet.y, 1, 1, -sprite_get_height(_st) / 2);
        }
        return;
    }

    var _layout = monster_GetDrawLayout(_slot, _monster);
    if (_pop) _layout.scale = UNIT_HOVER_SCALE;
    monsterAnim_Draw(_slot, _monster, _layout);
}

/// Slot layout moved along with the enemy while it runs up to attack (battlefx_UnitOffset).
/// top_y / left_x: where the slot box's top-left corner is drawn.
function monster_GetDrawLayout(_slot, _monster) {
    var _l = monster_GetSlotLayout(_slot);
    var _o = battlefx_UnitOffset(_monster);
    _l.cx += _o.x;
    _l.cy += _o.y;
    _l.sprite_y += _o.y;
    _l.health_x += _o.x;
    _l.health_y += _o.y;
    _l.stats_cx += _o.x;
    _l.atk_y += _o.y;
    _l.status_y += _o.y;
    _l.full_bottom += _o.y;
    _l.left_x = _slot.x + _o.x;
    _l.top_y = _slot.y + _o.y;
    return _l;
}

function monster_DrawActive(_slot, _monster, _pop = false) {
    monster_DrawBody(_slot, _monster, _pop);
    monster_DrawStats(_slot, _monster);
}

/// Name, keywords, health, ATK and status of an enemy (drawn over every enemy body)
function monster_DrawStats(_slot, _monster) {
    if (battlefx_IsArriving(_monster)) return;   // they appear with the enemy
    var _layout = monster_GetDrawLayout(_slot, _monster);

    // name above the head, keywords (e.g. Frontline) above the name
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    battle_DrawOutlinedText(_layout.cx, _layout.top_y - 2, _monster.name, monster_IsElite(_monster) ? make_color_rgb(255, 120, 100) : c_white);
    var _keywords = card_GetKeywordText(_monster);
    if (_keywords != "") battle_DrawOutlinedText(_layout.cx, _layout.top_y - 18, _keywords, make_color_rgb(150, 210, 255));
    draw_set_valign(fa_top);

    monster_DrawHealthBar(_layout.health_x, _layout.health_y, _layout.health_w, _layout.health_h,
        battlefx_DisplayHealth(_monster), _monster.max_health);

    // ATK right of the health bar (enemies stand close together: one line less under each of them)
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    battle_DrawOutlinedText(_layout.health_x + _layout.health_w + 6, _layout.atk_y, "ATK " + string(card_GetBoardAttackDisplay(_monster)), make_color_rgb(255, 184, 168));
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    card_DrawAttackGainBadge(_layout.left_x, _layout.top_y, _layout.card_w, _layout.card_h, card_GetAttackBuff(_monster));

    var _status = status_GetDisplayText(_monster);
    if (_status != "") {
        battle_DrawOutlinedText(_layout.stats_cx, _layout.status_y, _status, c_orange);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function SCR_Monster_DrawDebugCounter() {
    debug_DrawBattleStatus(id);
}

/// Empty enemy slot: nothing is drawn (the board's own art shows the spot)
function monster_DrawEmptySlot(_slot) {
}

function monster_SlotHasLiving(_slot) {
    return _slot.visible && _slot.occupied && _slot.card != undefined && _slot.card.alive;
}

/// Enemies far to near (they can overlap). Names and bars go over every body; the enemy under the
/// mouse is drawn last, whole and a bit bigger, so it pops out while the others stay behind.
function SCR_Monster_Draw() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    var _hover = unit_GetHoveredSlot(SIDE_ENEMY);
    var _order = unit_GetDepthOrder(SIDE_ENEMY, _hover);

    for (var o = 0; o < array_length(_order); o++) {
        var _slot = _board.enemy_slots[_order[o]];
        if (!_slot.visible) continue;
        if (!monster_SlotHasLiving(_slot)) { monster_DrawEmptySlot(_slot); continue; }
        if (_order[o] != _hover) monster_DrawBody(_slot, _slot.card, false);
    }
    for (var s = 0; s < array_length(_order); s++) {
        var _sslot = _board.enemy_slots[_order[s]];
        if (_order[s] != _hover && monster_SlotHasLiving(_sslot)) monster_DrawStats(_sslot, _sslot.card);
    }
    if (_hover >= 0) {
        var _hslot = _board.enemy_slots[_hover];
        if (monster_SlotHasLiving(_hslot)) monster_DrawActive(_hslot, _hslot.card, true);
    }

    SCR_Monster_DrawDebugCounter();
    debug_DrawEnemyHoverOverlay(id);
}

/// Mouse area of an enemy: its body down to the top of its pedestal (bars and text below are not part
/// of it, so enemies standing close together in a row don't fight over the mouse)
function monster_GetHitbox(_slot) {
    return {
        card_left: _slot.x,
        card_top: _slot.y,
        card_right: _slot.x + _slot.w,
        card_bottom: _slot.y + _slot.h,
        full_bottom: _slot.y + _slot.h + 7   // feet + 12
    };
}

function monster_IsPointOverSlot(_slot, _mx, _my) {
    var _box = monster_GetHitbox(_slot);
    return (_mx >= _box.card_left && _mx <= _box.card_right &&
            _my >= _box.card_top && _my <= _box.full_bottom);
}

function monster_IsMouseOverSlot(_slot) {
    return monster_IsPointOverSlot(_slot, mouse_x, mouse_y);
}

function SCR_Monster_UpdateHoverDebug() {
    hovered_enemy_slot = (active_slot_count > 0) ? unit_GetHoveredSlot(SIDE_ENEMY) : -1;
}

function SCR_Monster_DrawHoverDebug() {
    if (!DEBUG_DRAW_ENEMY_HITBOXES) return;
    if (active_slot_count <= 0) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = 0; i < array_length(_board.enemy_slots); i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible) continue;

        var _box = monster_GetHitbox(_slot);
        var _hovered = (i == hovered_enemy_slot);

        draw_set_color(_hovered ? c_lime : c_yellow);
        draw_rectangle(_box.card_left, _box.card_top, _box.card_right, _box.full_bottom, true);

        draw_set_color(_hovered ? c_red : c_aqua);
        draw_rectangle(_box.card_left, _box.card_top, _box.card_right, _box.card_bottom, true);

        draw_set_color(c_white);
        draw_text(_box.card_left + 2, _box.card_top + 2, "slot " + string(i));
    }

    if (hovered_enemy_slot >= 0) {
        draw_set_color(c_white);
        draw_text(10, 58, "Hover slot: " + string(hovered_enemy_slot));
    }

    draw_set_color(c_white);
}
