/// @desc Debug hover + hitbox overlay for enemy monsters

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
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible) continue;

        var _box = monster_GetHitbox(_slot);
        var _hovered = (i == hovered_enemy_slot);

        if (!_slot.occupied || _slot.card == undefined) {
            var _layout = monster_GetSlotLayout(_slot);
            draw_sprite_ext(SPR_MonsterSlot, 0, _layout.cx, _layout.cy, 1, 1, 0, c_white, 0.35);
        }

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
