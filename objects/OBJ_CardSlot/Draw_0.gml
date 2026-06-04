if (card_data == undefined) exit;

var _spr = -1;
switch (card_data.type) {
    case "monster":         _spr = SPR_Monsterplaceholder; break;
    case "special_monster": _spr = SPR_Monsterplaceholder; break;
    case "weapon":          _spr = SPR_Weaponplaceholder;  break;
    case "action":          _spr = SPR_Actionplaceholder;  break;
}

// === card background ===
draw_set_color(c_white);
draw_rectangle(x, y, x + card_w, y + card_h, false);

// === NAME at top ===
draw_set_color(c_black);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_text(x + card_w / 2, y + 5, card_data.name);

// === TYPE below name ===
switch (card_data.type) {
    case "monster":         draw_set_color(c_gray);   break;
    case "special_monster": draw_set_color(c_purple); break;
    case "weapon":          draw_set_color(c_red);    break;
    case "action":          draw_set_color(c_blue);   break;
}
draw_set_halign(fa_center);
draw_text(x + card_w / 2, y + 20, card_data.type);

// === PICTURE in middle ===
if (_spr != -1) {
    var _sw     = sprite_get_width(_spr);
    var _sh     = sprite_get_height(_spr);
    var _scale  = min(card_w / _sw, (card_h - 50) / _sh);
    var _draw_x = x + (card_w - _sw * _scale) / 2;
    var _draw_y = y + 38;
    draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _scale, _scale, 0, c_white, 1);
}

// === LEVEL bottom left (monsters only) ===
if (variable_struct_exists(card_data, "level")) {
    draw_set_color(c_yellow);
    draw_set_halign(fa_left);
    draw_text(x + 4, y + card_h - 16, "Lv " + string(card_data.level));
}

// === COUNT BADGE top right ===
if (count > 0) {
    draw_set_color(c_lime);
    draw_circle(x + card_w - 10, y + 10, 10, false);
    draw_set_color(c_black);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(x + card_w - 10, y + 10, string(count));
}

// reset
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);