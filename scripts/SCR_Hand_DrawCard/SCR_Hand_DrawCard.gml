function SCR_Hand_DrawCard(_index, _count, _spacing, _hovered, _start_x) {
    var _card = hand[_index];
    if (_card == undefined) return;

    var _box = SCR_Hand_GetCardHitbox(_index, _count, _spacing, hand_Y, _start_x, _hovered);
    var _spr = SCR_Hand_GetSprite(_card);

    draw_sprite_ext(_spr, 0, _box.center_x, _box.center_y, _box.scale, _box.scale, 0, c_white, 1);

    draw_set_halign(fa_center);
    draw_set_color(c_black);
    draw_text(_box.center_x, _box.top + 10, _card.name);

    if (variable_struct_exists(_card, "level")) {
        draw_set_color(c_yellow);
        draw_text(_box.center_x, _box.top + 25, "Lv " + string(_card.level));
    }

    draw_set_color(c_white);
    var _type = (_card.type == "special_monster") ? "spirit" : _card.type;
    draw_text(_box.center_x, _box.top + 40, _type);
}
