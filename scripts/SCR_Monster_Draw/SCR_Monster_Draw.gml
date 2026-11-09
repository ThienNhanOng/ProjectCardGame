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

function monster_DrawActive(_slot, _monster) {
    var _layout = monster_GetSlotLayout(_slot);

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

    monsterAnim_Draw(_slot, _monster, _layout);

    // name above the head
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    battle_DrawOutlinedText(_layout.cx, _slot.y - 2, _monster.name, monster_IsElite(_monster) ? make_color_rgb(255, 120, 100) : c_white);
    draw_set_valign(fa_top);

    monster_DrawHealthBar(_layout.health_x, _layout.health_y, _layout.health_w, _layout.health_h,
        battlefx_DisplayHealth(_monster), _monster.max_health);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    battle_DrawOutlinedText(_layout.stats_cx, _layout.atk_y, "ATK " + string(card_GetBoardAttackDisplay(_monster)), make_color_rgb(255, 184, 168));

    card_DrawAttackGainBadge(_slot.x, _slot.y, _layout.card_w, _layout.card_h, card_GetAttackBuff(_monster));

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

function SCR_Monster_Draw() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible) continue;

        if (_slot.occupied && _slot.card != undefined && _slot.card.alive) {
            monster_DrawActive(_slot, _slot.card);
        } else {
            monster_DrawEmptySlot(_slot);
        }
    }

    SCR_Monster_DrawDebugCounter();
    debug_DrawEnemyHoverOverlay(id);
}

function monster_GetHitbox(_slot) {
    var _layout = monster_GetSlotLayout(_slot);

    return {
        card_left: _slot.x,
        card_top: _slot.y,
        card_right: _slot.x + _slot.w,
        card_bottom: _slot.y + _slot.h,
        full_bottom: _layout.full_bottom
    };
}

function monster_IsMouseOverSlot(_slot) {
    var _box = monster_GetHitbox(_slot);
    return (mouse_x >= _box.card_left && mouse_x <= _box.card_right &&
            mouse_y >= _box.card_top && mouse_y <= _box.full_bottom);
}

function SCR_Monster_UpdateHoverDebug() {
    hovered_enemy_slot = -1;

    if (active_slot_count <= 0) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;

        if (monster_IsMouseOverSlot(_slot)) {
            hovered_enemy_slot = i;
            return;
        }
    }
}

function SCR_Monster_DrawHoverDebug() {
    if (!DEBUG_DRAW_ENEMY_HITBOXES) return;
    if (active_slot_count <= 0) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = 0; i < active_slot_count; i++) {
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
