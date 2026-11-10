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
    var _stats_pad = 18;   // below the pedestal (kept tight: the nearest enemies stand just above the bottom bar)
    var _health_h = 8;
    var _health_pad_x = 4;
    var _health_y = _slot.y + _card_h + _stats_pad;
    var _atk_y = _health_y + _health_h / 2;          // ATK sits right of the health bar (left-aligned, centred on it)
    var _status_y = _health_y + _health_h + 6;       // status under the bar

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
        full_bottom: _status_y + 16,
        scale: 1                       // draw size multiplier (the hovered enemy pops out bigger)
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
        // animated enemies without an icon: their idle (or stage) sprite
        var _set = monsterAnim_GetSpriteSet(_monster);
        if (_set != undefined) return _set.idle;
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
#macro MONSTER_ANIM_SCALE 0.95     // draw size of animated enemies (1 = full sprite size)
#macro MONSTER_FACING -1           // character sprites face right; enemies stand on the right, so they are mirrored to face left

/// { idle, attack } sprites for this monster, or undefined if it has no animated set
function monsterAnim_GetSpriteSet(_monster) {
    if (_monster == undefined || !variable_struct_exists(_monster, "sprite_name")) return undefined;
    var _idle = asset_get_index(_monster.sprite_name + "_Idle");
    if (_idle == -1) {
        // "<sprite>_Stages": one frame per turn on the field (an egg that cracks a bit more each turn)
        var _stages = asset_get_index(_monster.sprite_name + "_Stages");
        if (_stages != -1) return { idle: _stages, attack: _stages, stages: true };
        return undefined;
    }
    // attack sprites: <sprite>_Attack, then optional <sprite>_Attack2 .. _Attack9 (one is picked per attack)
    var _attacks = [];
    var _attack = asset_get_index(_monster.sprite_name + "_Attack");
    if (_attack != -1) array_push(_attacks, _attack);
    for (var k = 2; k <= 9; k++) {
        var _more = asset_get_index(_monster.sprite_name + "_Attack" + string(k));
        if (_more == -1) break;
        array_push(_attacks, _more);
    }
    if (array_length(_attacks) == 0) array_push(_attacks, _idle);
    return { idle: _idle, attack: _attacks[0], attacks: _attacks };
}

/// The attack sprite chosen for this monster's current attack
function monsterAnim_AttackSprite(_monster, _set) {
    if (!variable_struct_exists(_set, "attacks")) return _set.attack;
    var _pick = variable_struct_exists(_monster, "anim_attack_pick") ? _monster.anim_attack_pick : 0;
    if (_pick < 0 || _pick >= array_length(_set.attacks)) _pick = 0;
    return _set.attacks[_pick];
}

/// Play the attack animation once (enemy attacks or uses an ability); _delay_ms starts it later
function monsterAnim_PlayAttack(_monster, _delay_ms = 0) {
    if (_monster == undefined) return;
    _monster.anim_attack_start = current_time + _delay_ms;
    var _set = monsterAnim_GetSpriteSet(_monster);
    var _count = (_set != undefined && variable_struct_exists(_set, "attacks")) ? array_length(_set.attacks) : 1;
    var _fixed = struct_GetOr(_monster, "anim_attack_fixed", -1);   // set by the current move / stance
    _monster.anim_attack_pick = (_fixed >= 0 && _fixed < _count) ? _fixed : irandom(_count - 1);
}

/// How long the attack animation picked by monsterAnim_PlayAttack lasts (ms); 0 when it has none
function monsterAnim_AttackLengthMs(_monster) {
    var _set = monsterAnim_GetSpriteSet(_monster);
    if (_set == undefined || variable_struct_exists(_set, "stages")) return 0;
    return sprite_get_number(monsterAnim_AttackSprite(_monster, _set)) / MONSTER_ANIM_ATTACK_FPS * 1000;
}

function monsterAnim_IsAttacking(_monster, _set) {
    if (!variable_struct_exists(_monster, "anim_attack_start")) return false;
    var _len_ms = sprite_get_number(monsterAnim_AttackSprite(_monster, _set)) / MONSTER_ANIM_ATTACK_FPS * 1000;
    var _t = current_time - _monster.anim_attack_start;
    return _t >= 0 && _t < _len_ms;   // before its start time it keeps idling
}

function monsterAnim_DrawSpriteBody(_slot, _monster, _layout) {
    if (_layout == undefined) _layout = monster_GetSlotLayout(_slot);
    var _pop = struct_GetOr(_layout, "scale", 1);   // > 1 while the enemy is under the mouse
    var _sc = MONSTER_ANIM_SCALE * _pop;

    var _set = monsterAnim_GetSpriteSet(_monster);
    if (_set != undefined && variable_struct_exists(_set, "stages")) {
        // one stage per turn on the field; a gentle wobble, and a hard shake when it acts
        var _turns = 0;
        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone && variable_struct_exists(_monster, "spawn_turn")) _turns = _bm.turn_number - _monster.spawn_turn;
        var _stage = clamp(_turns, 0, sprite_get_number(_set.idle) - 1);
        var _rot = 2 * sin(current_time / 300);
        if (variable_struct_exists(_monster, "anim_attack_start")) {
            var _st = current_time - _monster.anim_attack_start;
            if (_st >= 0 && _st < 600) _rot = 9 * sin(_st / 35) * (1 - _st / 600);
        }
        draw_sprite_ext(_set.idle, _stage, _layout.cx, _layout.sprite_y + _layout.card_h * 0.58 - 5, _sc * MONSTER_FACING, _sc, _rot, c_white, battlefx_BlinkAlpha(_monster));
        return;
    }
    if (_set != undefined) {
        // each monster idles slightly out of step with the others
        if (!variable_struct_exists(_monster, "anim_phase")) _monster.anim_phase = random(1);
        var _spr = _set.idle;
        var _frame = 0;
        if (monsterAnim_IsAttacking(_monster, _set)) {
            _spr = monsterAnim_AttackSprite(_monster, _set);
            _frame = floor((current_time - _monster.anim_attack_start) / 1000 * MONSTER_ANIM_ATTACK_FPS);
        } else {
            _frame = floor((current_time / 1000 + _monster.anim_phase) * MONSTER_ANIM_IDLE_FPS);
        }
        _frame = _frame mod sprite_get_number(_spr);
        draw_sprite_ext(_spr, _frame, _layout.cx, _layout.sprite_y + _layout.card_h * 0.58 - 5, _sc * MONSTER_FACING, _sc, 0, c_white, battlefx_BlinkAlpha(_monster));
        return;
    }

    var _static = SCR_Monster_ResolveSprite(_monster);
    draw_sprite_ext(_static, 0, _layout.cx, _layout.sprite_y, _pop, _pop, 0, c_white, battlefx_BlinkAlpha(_monster));
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
