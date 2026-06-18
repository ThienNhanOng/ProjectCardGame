/// @desc Draw active enemies on board + debug wave counter

function monster_DrawHealthBar(_x, _y, _w, _h, _current, _max) {
    var _ratio = (_max > 0) ? clamp(_current / _max, 0, 1) : 0;

    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    draw_set_color(c_lime);
    draw_rectangle(_x, _y, _x + _w * _ratio, _y + _h, false);

    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(_x + _w / 2, _y - 1, string(_current) + "/" + string(_max));
    draw_set_halign(fa_left);
}

function monster_DrawActive(_slot, _monster) {
    var _card_w = _slot.w;
    var _card_h = _slot.h;
    var _spr = SCR_Monster_GetSprite(_monster);

    draw_sprite_ext(_spr, 0, _slot.x + _card_w / 2, _slot.y + _card_h / 2, 1, 1, 0, c_white, 1);

    draw_set_halign(fa_center);
    draw_set_color(c_black);
    draw_text(_slot.x + _card_w / 2, _slot.y + 5, _monster.name);

    draw_set_color(c_maroon);
    draw_text(_slot.x + _card_w / 2, _slot.y + _card_h - 28, "ATK " + string(_monster.attack));

    draw_set_color(c_navy);
    draw_text(_slot.x + _card_w / 2, _slot.y + _card_h - 16, SCR_Monster_GetAbilityText(_monster));

    monster_DrawHealthBar(_slot.x, _slot.y + _card_h + 4, _card_w, 8, _monster.health, _monster.max_health);

    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

function SCR_Monster_DrawDebugCounter() {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _living = (_board != noone) ? monster_CountLivingActive(_board) : 0;

    draw_set_color(c_yellow);
    draw_text(10, 10, "Queue: " + string(monster_GetQueueCount())
        + " | Slots: " + string(active_slot_count)
        + " | Field: " + string(_living));

    if (variable_instance_exists(id, "battle_name")) {
        draw_text(10, 26, "Battle: " + battle_name);
    }

    if (battle_won) {
        draw_set_color(c_lime);
        draw_text(10, 42, "Victory!");
    }

    draw_set_color(c_white);
}

function SCR_Monster_Draw() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;
        monster_DrawActive(_slot, _slot.card);
    }

    SCR_Monster_DrawDebugCounter();
    SCR_Monster_DrawHoverDebug();
}
