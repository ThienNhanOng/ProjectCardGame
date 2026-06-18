/// @desc Shared monster slot layout + sprite resolve (animation JSON or placeholder)

function monster_GetSlotLayout(_slot) {
    var _card_w = _slot.w;
    var _card_h = _slot.h;
    var _cx = _slot.x + _card_w / 2;
    var _cy = _slot.y + _card_h / 2 + 12;
    var _stats_pad = 6;
    var _health_h = 8;
    var _health_pad_x = 4;
    var _health_y = _slot.y + _card_h + _stats_pad;
    var _atk_y = _health_y + _health_h + 16;
    var _status_y = _atk_y + 16;

    return {
        cx: _cx,
        cy: _cy,
        card_w: _card_w,
        card_h: _card_h,
        sprite_y: _slot.y + _card_h * 0.42,
        health_x: _slot.x + _health_pad_x,
        health_w: _card_w - _health_pad_x * 2,
        health_y: _health_y,
        health_h: _health_h,
        stats_cx: _slot.x + _health_pad_x + (_card_w - _health_pad_x * 2) / 2,
        atk_y: _atk_y,
        status_y: _status_y,
        full_bottom: _status_y + 16
    };
}

function SCR_Monster_ResolveSprite(_monster) {
    if (_monster == undefined) return SPR_Monsterplaceholder;

    if (variable_struct_exists(_monster, "animation") && is_string(_monster.animation) && _monster.animation != "") {
        var _anim_idx = asset_get_index(_monster.animation);
        if (_anim_idx != -1) return _anim_idx;
    }

    if (variable_struct_exists(_monster, "sprite_name")) {
        var _spr_idx = asset_get_index(_monster.sprite_name);
        if (_spr_idx != -1) return _spr_idx;
    }

    return SPR_Monsterplaceholder;
}

function monsterAnim_DrawSpriteBody(_slot, _monster, _layout) {
    if (_layout == undefined) _layout = monster_GetSlotLayout(_slot);

    var _spr = SCR_Monster_ResolveSprite(_monster);
    draw_sprite_ext(_spr, 0, _layout.cx, _layout.sprite_y, 1, 1, 0, c_white, 1);
}

function monsterAnim_Default_Draw(_slot, _monster, _layout) {
    monsterAnim_DrawSpriteBody(_slot, _monster, _layout);
}

function monsterAnim_Default_Update(_monster) {
}
