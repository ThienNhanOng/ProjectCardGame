/// @desc Monster animations — registry + per-monster hooks (fill a hook in to give a monster custom animation)

function monsterAnim_GetKey(_monster) {
    return _monster.collection + ":" + string(_monster.id);
}

function monsterAnim_DrawByAnimation(_slot, _monster, _layout) {
    if (_monster == undefined) {
        monsterAnim_Default_Draw(_slot, _monster, _layout);
        return;
    }

    if (variable_struct_exists(_monster, "animation") && is_string(_monster.animation) && _monster.animation != "") {
        switch (_monster.animation) {
            case "GoblinSoldier": monsterAnim_GoblinSoldier_Draw(_slot, _monster, _layout); return;
            case "GoblinMage": monsterAnim_GoblinMage_Draw(_slot, _monster, _layout); return;
            case "GoblinCommander": monsterAnim_GoblinCommander_Draw(_slot, _monster, _layout); return;
        }
    }

    monsterAnim_Default_Draw(_slot, _monster, _layout);
}

function monsterAnim_UpdateByAnimation(_monster) {
    if (_monster == undefined) {
        monsterAnim_Default_Update(_monster);
        return;
    }

    if (variable_struct_exists(_monster, "animation") && is_string(_monster.animation) && _monster.animation != "") {
        switch (_monster.animation) {
            case "GoblinSoldier": monsterAnim_GoblinSoldier_Update(_monster); return;
            case "GoblinMage": monsterAnim_GoblinMage_Update(_monster); return;
            case "GoblinCommander": monsterAnim_GoblinCommander_Update(_monster); return;
        }
    }

    monsterAnim_Default_Update(_monster);
}

function monsterAnim_Draw(_slot, _monster, _layout) {
    switch (monsterAnim_GetKey(_monster)) {
        case "enemyGoblins_01:1": monsterAnim_GoblinSoldier_Draw(_slot, _monster, _layout); break;
        case "enemyGoblins_01:2": monsterAnim_GoblinMage_Draw(_slot, _monster, _layout); break;
        case "enemyGoblins_01:3": monsterAnim_GoblinCommander_Draw(_slot, _monster, _layout); break;
        case "enemyOrcs_01:1": monsterAnim_OrcBrute_Draw(_slot, _monster, _layout); break;
        case "enemyOrcs_01:2": monsterAnim_OrcShaman_Draw(_slot, _monster, _layout); break;
        default: monsterAnim_DrawByAnimation(_slot, _monster, _layout); break;
    }
}

function monsterAnim_Update(_monster) {
    switch (monsterAnim_GetKey(_monster)) {
        case "enemyGoblins_01:1": monsterAnim_GoblinSoldier_Update(_monster); break;
        case "enemyGoblins_01:2": monsterAnim_GoblinMage_Update(_monster); break;
        case "enemyGoblins_01:3": monsterAnim_GoblinCommander_Update(_monster); break;
        case "enemyOrcs_01:1": monsterAnim_OrcBrute_Update(_monster); break;
        case "enemyOrcs_01:2": monsterAnim_OrcShaman_Update(_monster); break;
        default: monsterAnim_UpdateByAnimation(_monster); break;
    }
}

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

/// Still picture of an enemy (hover preview / card art): its "icon" first, then its sprite
function SCR_Monster_ResolveSprite(_monster) {
    if (_monster == undefined) return SPR_Monsterplaceholder;

    if (variable_struct_exists(_monster, "icon_name") && _monster.icon_name != "") {
        var _icon_idx = asset_get_index(_monster.icon_name);
        if (_icon_idx != -1) return _icon_idx;
    }

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

// ---------------------------------------------------------------------------
// Animated sprite sets: a monster whose JSON "sprite" is e.g. "SPR_GoblinClub" uses
// SPR_GoblinClub_Idle (looping) and SPR_GoblinClub_Attack (played once when it attacks).
// Sprite origin is at the feet; they stand on the bottom edge of the enemy card.
// ---------------------------------------------------------------------------

#macro MONSTER_ANIM_IDLE_FPS 12
#macro MONSTER_ANIM_ATTACK_FPS 24
#macro MONSTER_ANIM_SCALE 0.82    // draw size of animated enemies (1 = full sprite size)

/// { idle, attack } sprites for this monster, or undefined if it has no animated set
function monsterAnim_GetSpriteSet(_monster) {
    if (_monster == undefined || !variable_struct_exists(_monster, "sprite_name")) return undefined;
    var _idle = asset_get_index(_monster.sprite_name + "_Idle");
    if (_idle == -1) return undefined;
    var _attack = asset_get_index(_monster.sprite_name + "_Attack");
    return { idle: _idle, attack: (_attack != -1) ? _attack : _idle };
}

/// Play the attack animation once (enemy attacks or uses an ability); _delay_ms starts it later
function monsterAnim_PlayAttack(_monster, _delay_ms = 0) {
    if (_monster == undefined) return;
    _monster.anim_attack_start = current_time + _delay_ms;
}

function monsterAnim_IsAttacking(_monster, _set) {
    if (!variable_struct_exists(_monster, "anim_attack_start")) return false;
    var _len_ms = sprite_get_number(_set.attack) / MONSTER_ANIM_ATTACK_FPS * 1000;
    var _t = current_time - _monster.anim_attack_start;
    return _t >= 0 && _t < _len_ms;   // before its start time it keeps idling
}

function monsterAnim_DrawSpriteBody(_slot, _monster, _layout) {
    if (_layout == undefined) _layout = monster_GetSlotLayout(_slot);

    var _set = monsterAnim_GetSpriteSet(_monster);
    if (_set != undefined) {
        // each monster idles slightly out of step with the others
        if (!variable_struct_exists(_monster, "anim_phase")) _monster.anim_phase = random(1);
        var _spr = _set.idle;
        var _frame = 0;
        if (monsterAnim_IsAttacking(_monster, _set)) {
            _spr = _set.attack;
            _frame = floor((current_time - _monster.anim_attack_start) / 1000 * MONSTER_ANIM_ATTACK_FPS);
        } else {
            _frame = floor((current_time / 1000 + _monster.anim_phase) * MONSTER_ANIM_IDLE_FPS);
        }
        _frame = _frame mod sprite_get_number(_spr);
        draw_sprite_ext(_spr, _frame, _layout.cx, _layout.sprite_y + _layout.card_h * 0.58 - 5, MONSTER_ANIM_SCALE, MONSTER_ANIM_SCALE, 0, c_white, battlefx_BlinkAlpha(_monster));
        return;
    }

    var _static = SCR_Monster_ResolveSprite(_monster);
    draw_sprite_ext(_static, 0, _layout.cx, _layout.sprite_y, 1, 1, 0, c_white, battlefx_BlinkAlpha(_monster));
}

function monsterAnim_Default_Draw(_slot, _monster, _layout) {
    monsterAnim_DrawSpriteBody(_slot, _monster, _layout);
}

function monsterAnim_Default_Update(_monster) {
}

function monsterAnim_GoblinSoldier_Draw(_slot, _monster, _layout) {
    monsterAnim_DrawSpriteBody(_slot, _monster, _layout);
}

function monsterAnim_GoblinSoldier_Update(_monster) {
}

function monsterAnim_GoblinMage_Draw(_slot, _monster, _layout) {
    monsterAnim_DrawSpriteBody(_slot, _monster, _layout);
}

function monsterAnim_GoblinMage_Update(_monster) {
}

function monsterAnim_GoblinCommander_Draw(_slot, _monster, _layout) {
    monsterAnim_DrawSpriteBody(_slot, _monster, _layout);
}

function monsterAnim_GoblinCommander_Update(_monster) {
}

function monsterAnim_OrcBrute_Draw(_slot, _monster, _layout) {
    monsterAnim_DrawSpriteBody(_slot, _monster, _layout);
}

function monsterAnim_OrcBrute_Update(_monster) {
}

function monsterAnim_OrcShaman_Draw(_slot, _monster, _layout) {
    monsterAnim_DrawSpriteBody(_slot, _monster, _layout);
}

function monsterAnim_OrcShaman_Update(_monster) {
}
