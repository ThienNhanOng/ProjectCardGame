/// @desc Draw active enemies on board + debug wave counter

function monster_DrawHealthBar(_x, _y, _w, _h, _current, _max) {
    var _ratio = (_max > 0) ? clamp(_current / _max, 0, 1) : 0;

    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    draw_set_color(c_lime);
    draw_rectangle(_x, _y, _x + _w * _ratio, _y + _h, false);

    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_x + _w / 2, _y + _h / 2, string(_current) + "/" + string(_max));
    draw_set_valign(fa_top);
}

function monster_DrawActive(_slot, _monster) {
    var _layout = monster_GetSlotLayout(_slot);

    draw_sprite_ext(SPR_MonsterSlot, 0, _layout.cx, _layout.cy, 1, 1, 0, c_white, 1);

    monsterAnim_Draw(_slot, _monster, _layout);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(monster_IsElite(_monster) ? c_red : c_black);
    draw_text(_slot.x + 4, _slot.y + 5, SCR_Hand_TruncateName(_monster.name, _layout.card_w - 8));

    monster_DrawHealthBar(_layout.health_x, _layout.health_y, _layout.health_w, _layout.health_h,
        _monster.health, _monster.max_health);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_maroon);
    draw_text(_layout.stats_cx, _layout.atk_y, "ATK " + string(_monster.attack));

    card_DrawAttackGainBadge(_slot.x, _slot.y, _layout.card_w, _layout.card_h, card_GetAttackBuff(_monster));

    var _status = status_GetDisplayText(_monster);
    if (_status != "") {
        draw_set_color(c_orange);
        draw_text(_layout.stats_cx, _layout.status_y, _status);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function SCR_Monster_DrawDebugCounter() {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _living = (_board != noone) ? monster_CountLivingActive(_board) : 0;

    draw_set_color(c_yellow);
    var _db_count = (variable_global_exists("monster_DB") && is_struct(global.monster_DB))
        ? array_length(global.monster_DB.enemies) : 0;

    draw_text(10, 10, "Queue: " + string(monster_GetQueueCount())
        + " | Slots: " + string(active_slot_count)
        + " | Field: " + string(_living)
        + " | DB: " + string(_db_count));

    if (variable_instance_exists(id, "battle_name")) {
        draw_text(10, 26, "Battle: " + battle_name);
    }

    if (battle_won) {
        draw_set_color(c_lime);
        draw_text(10, 42, "Victory!");
    }

    draw_set_color(c_white);
}

function monster_DrawEmptySlot(_slot) {
    var _layout = monster_GetSlotLayout(_slot);
    draw_sprite_ext(SPR_MonsterSlot, 0, _layout.cx, _layout.cy, 1, 1, 0, c_white, 0.45);
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
    SCR_Monster_DrawHoverDebug();
}
