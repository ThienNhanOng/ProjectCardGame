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

// === NAME at top center ===
draw_set_color(c_black);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_text_ext(x + card_w / 2, y + 4, card_data.name, -1, card_w - 4);

// === TYPE below name ===
switch (card_data.type) {
    case "monster":         draw_set_color(c_gray);   break;
    case "special_monster": draw_set_color(c_purple); break;
    case "weapon":          draw_set_color(c_red);    break;
    case "action":          draw_set_color(c_blue);   break;
}
draw_set_halign(fa_center);
draw_text(x + card_w / 2, y + 18, card_data.type);

// === PICTURE centered in remaining space ===
if (_spr != -1) {
    var _sw           = sprite_get_width(_spr);
    var _sh           = sprite_get_height(_spr);
    var _pic_area_top = y + 34;
    var _pic_area_h   = card_h - 50;
    var _scale        = min((card_w - 10) / _sw, _pic_area_h / _sh);
    
    // since origin is Middle Center, draw at the center point of the area
    var _draw_x = x + (card_w / 2);
    var _draw_y = _pic_area_top + (_pic_area_h / 2);
    
    draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _scale, _scale, 0, c_white, 1);
}

// === LEVEL bottom left (monsters only) ===
if (variable_struct_exists(card_data, "level")) {
    draw_set_color(c_yellow);
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);
    draw_text(x + 4, y + card_h - 4, "Lv " + string(card_data.level));
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