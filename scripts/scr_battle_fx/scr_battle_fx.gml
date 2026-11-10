/// @desc Battle hit effects: the dashed targeting arrow, enemy attack arrows, the sword-swing slash and the hit blink.
///
/// - While you pick an enemy to hit, a dashed arrow runs from your attacker to the mouse
///   (it snaps to and turns red over a valid enemy).
/// - Every hit (combat_DamageUnit) plays SPR_FX_Slash on the target and makes it blink for a second,
///   while its health bar drains smoothly from the old value to the new one (display only).
/// - An attacker (enemy, or your monster striking with its weapon / an action card) runs up beside its target,
///   strikes, and walks back to its spot; the slash + blink + health drain land when the blow does.
///   Attacks on several targets stop beside the middle of the group and send an arrow to each.
/// - A unit that dies drops into a pile of bones that fades (SPR_FX_Bones).
/// - A unit that takes a spot arrives as a dark shadow, either hopping in from its side of the screen
///   or dropping straight down from above (picked at random, or fixed with the unit's JSON "arrival":
///   "side" / "drop"); a puff of smoke (SPR_FX_Smoke) on arrival reveals the real sprite.

#macro BATTLEFX_ARROW_GROW 300      // ms for an enemy attack arrow to reach its target
#macro BATTLEFX_ARROW_HOLD 300      // ms it takes to fade once the hit has landed
#macro BATTLEFX_STRIKE_MS 330       // ms into the enemy attack animation when the blow lands
#macro BATTLEFX_SLASH_FPS 24
#macro BATTLEFX_SLASH_SCALE 0.8
#macro BATTLEFX_BLINK_MS 1000
#macro BATTLEFX_BLINK_RATE 90       // ms per blink half-cycle
#macro BATTLEFX_BONES_FPS 20
#macro BATTLEFX_BONES_HOLD 500      // ms the pile rests after landing
#macro BATTLEFX_BONES_FADE 500      // ms it takes to fade away
#macro BATTLEFX_BONES_SCALE 1.2
#macro BATTLEFX_RUN_MS 650          // the arriving shadow hops in from the side / drops from above
#macro BATTLEFX_DROP_CHANCE 0.5     // chance an arrival drops from above instead of hopping in
#macro BATTLEFX_SMOKE_FPS 24
#macro BATTLEFX_REVEAL_MS 160       // ms into the smoke when the real sprite appears
#macro BATTLEFX_REPLACE_DELAY 650   // a replacement enemy waits for the bones to land
#macro BATTLEFX_START_STAGGER 220   // enemies at the start of a battle arrive one after another
#macro BATTLEFX_BAR_SPACING 18       // one "|" per this many pixels of distance
#macro BATTLEFX_HEAD_GAP 24          // room left before the ">" head
#macro BATTLEFX_AURA_MS 1100         // buff / debuff particle burst
#macro BATTLEFX_DEBUFF_FALLS true    // debuff particles sink downward (false = they rise like a buff, in red)
#macro BATTLEFX_DASH_OUT_MS 260      // an attacker runs up to its target...
#macro BATTLEFX_DASH_BACK_MS 340     // ...and walks back to its spot after the blow
#macro BATTLEFX_DASH_GAP 85          // it stops this far beside the target (on the side it came from)
#macro BATTLEFX_DASH_HOP 9           // little hops while it runs (pixels)
#macro BATTLEFX_PLAYER_STRIKE_MS 90  // your units (no attack animation) land the blow this long after arriving
#macro BATTLEFX_GHOST_LINGER_MS 260  // a unit killed by a delayed blow stays visible this long after the blow lands

function battlefx_Init() {
    if (!variable_global_exists("battle_fx")) global.battle_fx = [];
    if (!variable_global_exists("battlefx_hit_delay")) global.battlefx_hit_delay = 0;
    if (!variable_global_exists("battlefx_hero_blink")) global.battlefx_hero_blink = -100000;
    if (!variable_global_exists("battlefx_hero_hp_from")) global.battlefx_hero_hp_from = -1;
    if (!variable_global_exists("battlefx_spawn_delay")) global.battlefx_spawn_delay = -1;
}

/// Clear leftovers from the previous battle
function battlefx_Reset() {
    global.battle_fx = [];
    global.battlefx_hit_delay = 0;
    global.battlefx_hero_blink = -100000;
    global.battlefx_hero_hp_from = -1;
}

// ---------------------------------------------------------------------------
// Positions
// ---------------------------------------------------------------------------

/// Centre of a unit on screen (the player hero = the player health bar)
function battlefx_UnitPos(_side, _slot) {
    if (_side == SIDE_PLAYER && _slot == UNIT_HERO) {
        var _r = battle_GetPlayerHealthBarRect();
        return { x: (_r.left + _r.right) / 2, y: (_r.top + _r.bottom) / 2 };
    }
    var _b = unit_GetBoardSlot(_side, _slot);
    if (_b == undefined) return undefined;
    if (_side == SIDE_ENEMY) {
        var _l = monster_GetSlotLayout(_b);
        return { x: _l.cx, y: _l.sprite_y + _l.card_h * 0.58 - 40 };   // the middle of the monster's body
    }
    return { x: _b.x + _b.w / 2, y: _b.y + _b.h / 2 };
}

// ---------------------------------------------------------------------------
// Triggers
// ---------------------------------------------------------------------------

/// A unit takes a hit: sword swing on it + blink (after the current hit delay)
function battlefx_Hit(_side, _slot) {
    battlefx_Init();
    var _pos = battlefx_UnitPos(_side, _slot);
    if (_pos == undefined) return;
    var _start = current_time + global.battlefx_hit_delay;

    // the slash art swings the way an enemy hits you; blows on enemies come from your side, so it is mirrored
    array_push(global.battle_fx, { type: "slash", x: _pos.x, y: _pos.y, start: _start, flip: (_side == SIDE_ENEMY) ? -1 : 1 });

    if (_side == SIDE_PLAYER && _slot == UNIT_HERO) {
        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) global.battlefx_hero_hp_from = battlefx_HeroDisplayHealth(_bm.player_health);
        global.battlefx_hero_blink = _start;
    } else {
        var _card = unit_Get(_side, _slot);
        if (_card != undefined) {
            if (variable_struct_exists(_card, "health")) _card.fx_hp_from = battlefx_DisplayHealth(_card);
            _card.fx_blink_start = _start;
        }
    }
}

// ---------------------------------------------------------------------------
// Death and arrival
// ---------------------------------------------------------------------------

/// Where a unit's feet are (enemy pedestal, or the bottom of your monster spot)
function battlefx_UnitFeet(_side, _slot) {
    if (_side == SIDE_ENEMY) return battle_LayoutEnemyFeet(_slot);
    var _b = unit_GetBoardSlot(_side, _slot);
    if (_b == undefined) return undefined;
    return { x: _b.x + _b.w / 2, y: _b.y + _b.h - 10 };
}

/// Buff / debuff burst on a unit. _kind: "buff" (yellow: attack up, heal) or "debuff" (red: silence, shroud, ...)
function battlefx_Aura(_side, _slot, _kind) {
    battlefx_Init();
    if (battlefx_UnitFeet(_side, _slot) == undefined) return;
    array_push(global.battle_fx, { type: "aura", side: _side, slot: _slot, kind: _kind,
        start: current_time + global.battlefx_hit_delay, seed: random(1000) });
}

/// Same for every target in a targets list (from targets_Single / targets_All...)
function battlefx_AuraTargets(_targets, _kind) {
    for (var i = 0; i < array_length(_targets); i++) battlefx_Aura(_targets[i].side, _targets[i].slot, _kind);
}

function battlefx_Rand(_k, _seed) {
    return frac(abs(sin(_k * 12.9898 + _seed * 78.233) * 43758.5453));
}

/// four-point twinkle
function battlefx_DrawTwinkle(_x, _y, _r) {
    var _w = _r * 0.22;
    draw_triangle(_x - _r, _y, _x, _y - _w, _x, _y + _w, false);
    draw_triangle(_x + _r, _y, _x, _y - _w, _x, _y + _w, false);
    draw_triangle(_x, _y - _r, _x - _w, _y, _x + _w, _y, false);
    draw_triangle(_x, _y + _r, _x - _w, _y, _x + _w, _y, false);
}

function battlefx_DrawAura(_fx, _t) {
    var _f = battlefx_UnitFeet(_fx.side, _fx.slot);
    if (_f == undefined) return;
    var _buff = (_fx.kind == "buff");
    var _col = _buff ? make_color_rgb(255, 196, 30) : make_color_rgb(232, 24, 24);
    var _core = _buff ? make_color_rgb(255, 246, 170) : make_color_rgb(255, 120, 110);
    var _rise = _buff || !BATTLEFX_DEBUFF_FALLS;
    var _u = _t / BATTLEFX_AURA_MS;
    var _h = (_fx.side == SIDE_ENEMY) ? 104 : 92;

    // buffs glow (additive); red would vanish into the grass that way, so debuffs are drawn solid
    if (_buff) gpu_set_blendmode(bm_add);

    // soft column of light and a ring pulsing out at the feet
    draw_set_color(_col);
    draw_set_alpha(0.16 * sin(_u * pi));
    draw_ellipse(_f.x - 26, _f.y - _h, _f.x + 26, _f.y + 4, false);
    var _rr = 26 + 30 * _u;
    draw_set_alpha(0.6 * (1 - _u));
    draw_ellipse(_f.x - _rr, _f.y - _rr * 0.26, _f.x + _rr, _f.y + _rr * 0.26, true);
    draw_ellipse(_f.x - _rr + 2, _f.y - _rr * 0.26 + 1, _f.x + _rr - 2, _f.y + _rr * 0.26 - 1, true);

    // particles streaming up (buff) or sinking down (debuff), each with a short tail
    for (var k = 0; k < 18; k++) {
        var _r1 = battlefx_Rand(k + 1, _fx.seed);
        var _r2 = battlefx_Rand(k + 31, _fx.seed);
        var _p = (_u - _r1 * 0.45) / 0.55;
        if (_p <= 0 || _p >= 1) continue;
        var _dist = _p * _h * (0.75 + _r2 * 0.45);
        var _px = _f.x + (_r2 - 0.5) * 58 + sin(_p * 6 + k) * 3;
        var _py = _rise ? (_f.y - 4 - _dist) : (_f.y - _h - 8 + _dist);
        var _s = 1.8 + _r1 * 2.4;
        var _tail = _rise ? 8 : -8;
        draw_set_alpha(sin(_p * pi));
        draw_set_color(_col);
        draw_line_width(_px, _py, _px, _py + _tail, _s);
        draw_set_color(_core);
        draw_circle(_px, _py, _s * 0.55, false);
    }

    // twinkles popping around the body
    for (var k2 = 0; k2 < 6; k2++) {
        var _q = (_u - k2 * 0.1) / 0.35;
        if (_q <= 0 || _q >= 1) continue;
        var _sx = _f.x + (battlefx_Rand(k2 + 61, _fx.seed) - 0.5) * 64;
        var _sy = _f.y - _h * (0.25 + 0.7 * battlefx_Rand(k2 + 91, _fx.seed));
        var _sr = 11 * sin(_q * pi);
        draw_set_alpha(1);
        draw_set_color(_col);
        battlefx_DrawTwinkle(_sx, _sy, _sr);
        draw_set_color(_core);
        battlefx_DrawTwinkle(_sx, _sy, _sr * 0.5);
    }

    // two chevrons over the head: up for a buff, down for a debuff
    var _ca = sin(min(1, _u * 1.6) * pi);
    if (_ca > 0) {
        var _dir = _rise ? -1 : 1;
        var _cy = _f.y - _h - 14 + _dir * 10 * _u;
        for (var c = 0; c < 2; c++) {
            var _yy = _cy + c * 7 * -_dir;
            draw_set_alpha(_ca * (1 - c * 0.35));
            draw_set_color(c_black);
            draw_line_width(_f.x - 8, _yy - _dir * 5, _f.x, _yy, 4);
            draw_line_width(_f.x, _yy, _f.x + 8, _yy - _dir * 5, 4);
            draw_set_color(_col);
            draw_line_width(_f.x - 8, _yy - _dir * 5, _f.x, _yy, 2.4);
            draw_line_width(_f.x, _yy, _f.x + 8, _yy - _dir * 5, 2.4);
        }
    }

    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// A unit dies: its bones drop where it stood and fade away. When the blow is still on its way
/// (an attacker running up to it), the unit stays visible as a "ghost" until the blow lands.
function battlefx_Death(_side, _slot) {
    battlefx_Init();
    var _f = battlefx_UnitFeet(_side, _slot);
    if (_f == undefined) return;
    array_push(global.battle_fx, { type: "bones", x: _f.x, y: _f.y, start: current_time + global.battlefx_hit_delay,
        flip: (_side == SIDE_ENEMY) ? -1 : 1 });

    var _card = unit_Get(_side, _slot);
    if (global.battlefx_hit_delay > 0 && _card != undefined) {
        array_push(global.battle_fx, { type: "ghost", side: _side, slot: _slot, card: _card, start: current_time,
            life_ms: global.battlefx_hit_delay + BATTLEFX_GHOST_LINGER_MS });
    }
}

/// Draw a unit that already left the board but whose fatal blow hasn't landed yet
function battlefx_DrawGhost(_fx) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;
    if (_fx.side == SIDE_ENEMY) {
        monster_DrawActive(_board.enemy_slots[_fx.slot], _fx.card, false);
        return;
    }
    with (_board) {
        var _s = player_monster_slots[_fx.slot];
        SCR_Board_DrawPlayerUnit(_fx.slot, false, _fx.card);
        SCR_Board_DrawPlayerMonsterOverlay(_s, _s.w, _s.h, _fx.card);
    }
}

// ---------------------------------------------------------------------------
// Dash: an attacker runs up beside its target, strikes, and walks back to its spot.
// Its circle, health bar and name move with it (battlefx_UnitOffset is added wherever it is drawn).
// ---------------------------------------------------------------------------

/// Where an attack on these targets is delivered from: beside the target, on the side the attacker
/// comes from (beside the middle of a group for attacks on several). The player is reached at your front row.
function battlefx_DashDestination(_side, _slot, _targets) {
    var _home = battlefx_UnitFeet(_side, _slot);
    if (_home == undefined) return undefined;
    var _sx = 0;
    var _sy = 0;
    var _n = 0;
    for (var i = 0; i < array_length(_targets); i++) {
        var _t = _targets[i];
        var _p = (_t.side == SIDE_PLAYER && _t.slot == UNIT_HERO) ? battle_LayoutPlayerFeet(1) : battlefx_UnitFeet(_t.side, _t.slot);
        if (_p == undefined) continue;
        _sx += _p.x;
        _sy += _p.y;
        _n++;
    }
    if (_n <= 0) return undefined;
    var _tx = _sx / _n;
    var _dir = (_home.x >= _tx) ? 1 : -1;
    return { x: _tx + _dir * BATTLEFX_DASH_GAP, y: _sy / _n };
}

/// Send a unit to _dest (feet position): it runs there, stays _hold_ms, then walks back
function battlefx_Dash(_card, _side, _slot, _dest, _hold_ms) {
    var _home = battlefx_UnitFeet(_side, _slot);
    if (_card == undefined || _home == undefined || _dest == undefined) return;
    _card.fx_dash = { start: current_time, dx: _dest.x - _home.x, dy: _dest.y - _home.y, hold: max(0, _hold_ms) };
}

/// How far a unit is from its own spot right now, { x, y } (0, 0 when it isn't dashing)
function battlefx_UnitOffset(_card) {
    if (!is_struct(_card) || !variable_struct_exists(_card, "fx_dash") || _card.fx_dash == undefined) return { x: 0, y: 0 };
    var _d = _card.fx_dash;
    var _t = current_time - _d.start;
    var _back_at = BATTLEFX_DASH_OUT_MS + _d.hold;
    var _u = 0;      // 0 = at its spot, 1 = beside the target
    var _hop = 0;
    if (_t <= 0) {
        _u = 0;
    } else if (_t < BATTLEFX_DASH_OUT_MS) {
        var _p = _t / BATTLEFX_DASH_OUT_MS;
        _u = 1 - power(1 - _p, 2);                            // quick start, slows as it arrives
        _hop = abs(sin(_p * pi * 2)) * BATTLEFX_DASH_HOP;
    } else if (_t < _back_at) {
        _u = 1;
    } else if (_t < _back_at + BATTLEFX_DASH_BACK_MS) {
        var _q = (_t - _back_at) / BATTLEFX_DASH_BACK_MS;
        _u = 1 - (_q * _q * (3 - 2 * _q));                    // eases off, then settles at its spot
        _hop = abs(sin(_q * pi * 2)) * BATTLEFX_DASH_HOP;
    } else {
        _card.fx_dash = undefined;
        return { x: 0, y: 0 };
    }
    return { x: _d.dx * _u, y: _d.dy * _u - _hop };
}

function battlefx_IsDashing(_card) {
    return is_struct(_card) && variable_struct_exists(_card, "fx_dash") && _card.fx_dash != undefined;
}

/// Arrows from where an attacker stops to each of several targets, shown once it arrives
function battlefx_GroupArrows(_dest, _targets, _arrive_ms, _land_after_ms) {
    if (array_length(_targets) <= 1) return;
    for (var i = 0; i < array_length(_targets); i++) {
        var _to = battlefx_UnitPos(_targets[i].side, _targets[i].slot);
        if (_to == undefined) continue;
        array_push(global.battle_fx, { type: "arrow", x1: _dest.x, y1: _dest.y - 50, x2: _to.x, y2: _to.y,
            start: current_time + _arrive_ms, land: _land_after_ms });
    }
}

/// One of your units attacks these targets: it runs up to them and the blow lands just after it arrives.
/// Call before the damage is dealt; battlefx_EndDelay() after.
function battlefx_PlayerAttack(_slot, _targets) {
    battlefx_Init();
    var _card = unit_Get(SIDE_PLAYER, _slot);
    var _dest = battlefx_DashDestination(SIDE_PLAYER, _slot, _targets);
    if (_card == undefined || _dest == undefined) return;
    battlefx_Dash(_card, SIDE_PLAYER, _slot, _dest, BATTLEFX_PLAYER_STRIKE_MS + 260);
    battlefx_GroupArrows(_dest, _targets, BATTLEFX_DASH_OUT_MS, BATTLEFX_PLAYER_STRIKE_MS);
    global.battlefx_hit_delay = BATTLEFX_DASH_OUT_MS + BATTLEFX_PLAYER_STRIKE_MS;
}

/// A unit takes a spot: it comes in as a shadow from its own side (yours from the left, enemies from the right),
/// then a puff of smoke reveals it. _delay_ms: wait before it starts (e.g. for the bones of the one it replaces)
function battlefx_Arrive(_card, _side, _slot, _delay_ms) {
    battlefx_Init();
    if (_card == undefined) return;
    var _f = battlefx_UnitFeet(_side, _slot);
    if (_f == undefined) return;
    _card.fx_arrive_start = current_time + _delay_ms;
    _card.fx_arrive_from = (_side == SIDE_ENEMY) ? room_width + 70 : -70;
    // "side" = hops in from its side, "drop" = falls from above; JSON "arrival" fixes it for a unit
    if (variable_struct_exists(_card, "arrival") && (_card.arrival == "side" || _card.arrival == "drop")) _card.fx_arrive_style = _card.arrival;
    else _card.fx_arrive_style = (random(1) < BATTLEFX_DROP_CHANCE) ? "drop" : "side";
    array_push(global.battle_fx, { type: "smoke", x: _f.x, y: _f.y, start: _card.fx_arrive_start + BATTLEFX_RUN_MS });
}

/// An egg hatches in place: shell pieces fly off, smoke, and the hatchling is revealed (no run-in)
function battlefx_Hatch(_card, _slot) {
    battlefx_Init();
    var _f = battlefx_UnitFeet(SIDE_ENEMY, _slot);
    if (_f == undefined) return;
    _card.fx_arrive_style = "hatch";
    _card.fx_arrive_start = current_time - BATTLEFX_RUN_MS;   // already "arrived": straight into the smoke
    _card.fx_arrive_from = _f.x;
    array_push(global.battle_fx, { type: "smoke", x: _f.x, y: _f.y, start: current_time });
    array_push(global.battle_fx, { type: "shell", x: _f.x, y: _f.y - 32, start: current_time });
}

/// Delay for an enemy entering slot _slot: after a death it waits for the bones, at the start they come in turn
function battlefx_SpawnDelay(_slot) {
    battlefx_Init();
    if (global.battlefx_spawn_delay >= 0) return global.battlefx_spawn_delay;
    return _slot * BATTLEFX_START_STAGGER;
}

/// True while the unit is still on its way in (shadow) or hidden by the smoke
function battlefx_IsArriving(_card) {
    if (_card == undefined || !variable_struct_exists(_card, "fx_arrive_start")) return false;
    return current_time < _card.fx_arrive_start + BATTLEFX_RUN_MS + BATTLEFX_REVEAL_MS;
}

/// The arriving unit's dark shadow hopping toward its spot (feet target _tx, _ty).
/// _spr/_frame/_xs/_ys: how the unit itself is drawn; _yoff shifts sprites whose origin is not at the feet.
function battlefx_DrawArrivalShadow(_card, _spr, _frame, _tx, _ty, _xs, _ys, _yoff = 0) {
    var _t = current_time - _card.fx_arrive_start;
    if (_t < 0 || _t >= BATTLEFX_RUN_MS) return;
    var _u = _t / BATTLEFX_RUN_MS;
    var _x = _tx;
    var _y = _ty;
    var _gs = 1;     // ground shadow size
    if (variable_struct_exists(_card, "fx_arrive_style") && _card.fx_arrive_style == "drop") {
        // falls straight down from above the screen, speeding up, with a little squash as it lands
        var _fall = _u * _u;
        _y = lerp(-40, _ty, _fall);
        _gs = 0.3 + 0.7 * _fall;
        if (_u > 0.9) _ys *= 1 - (0.15 * (1 - (_u - 0.9) / 0.1));
    } else {
        // hops in from its side of the screen, three hops on the way
        _x = lerp(_card.fx_arrive_from, _tx, 1 - power(1 - _u, 2));
        _y = _ty - abs(sin(_u * pi * 3)) * 24 * (1 - _u * 0.4);
        _gs = 1 - (_ty - _y) / 80;
    }
    draw_set_alpha(0.3 * _gs);
    draw_set_color(c_black);
    draw_ellipse(_x - 28 * _gs, _ty - 5, _x + 28 * _gs, _ty + 6, false);
    draw_set_alpha(1);
    gpu_set_fog(true, make_color_rgb(18, 14, 12), 0, 1);
    draw_sprite_ext(_spr, _frame, _x, _y + _yoff, _xs, _ys, 0, c_white, 0.88);
    gpu_set_fog(false, c_black, 0, 1);
}

/// An enemy attacks these targets:
///   1. it runs up beside its target (beside the middle of the group for attack-all, with arrows to each)
///   2. its attack animation plays there
///   3. the hits (slash, blink, health drain) land BATTLEFX_STRIKE_MS into that animation
///   4. it walks back to its spot once the animation is over
/// Call before the damage is dealt; battlefx_EndDelay() after.
function battlefx_EnemyAttack(_enemy_slot, _targets) {
    battlefx_Init();
    var _monster = unit_Get(SIDE_ENEMY, _enemy_slot);
    var _dest = battlefx_DashDestination(SIDE_ENEMY, _enemy_slot, _targets);
    if (_monster == undefined || _dest == undefined) return;

    monsterAnim_PlayAttack(_monster, BATTLEFX_DASH_OUT_MS);
    var _hold = max(monsterAnim_AttackLengthMs(_monster), BATTLEFX_STRIKE_MS + 200);
    battlefx_Dash(_monster, SIDE_ENEMY, _enemy_slot, _dest, _hold);
    battlefx_GroupArrows(_dest, _targets, BATTLEFX_DASH_OUT_MS, BATTLEFX_STRIKE_MS);
    global.battlefx_hit_delay = BATTLEFX_DASH_OUT_MS + BATTLEFX_STRIKE_MS;
}

function battlefx_EndDelay() {
    battlefx_Init();
    global.battlefx_hit_delay = 0;
}

// ---------------------------------------------------------------------------
// Blink
// ---------------------------------------------------------------------------

function battlefx_BlinkAlphaFrom(_start) {
    var _t = current_time - _start;
    if (_t < 0 || _t > BATTLEFX_BLINK_MS) return 1;
    return ((_t div BATTLEFX_BLINK_RATE) mod 2 == 0) ? 0.2 : 1;
}

/// Alpha to draw a card / monster with (1 when it isn't blinking)
function battlefx_BlinkAlpha(_card) {
    if (_card == undefined || !variable_struct_exists(_card, "fx_blink_start")) return 1;
    return battlefx_BlinkAlphaFrom(_card.fx_blink_start);
}

// ---------------------------------------------------------------------------
// Health drain: bars show a value that slides from the old health to the new one during the blink
// ---------------------------------------------------------------------------

/// 0 -> 1 over the blink (eased); 0 while waiting for an enemy arrow to land
function battlefx_DrainProgress(_start) {
    var _t = (current_time - _start) / BATTLEFX_BLINK_MS;
    if (_t <= 0) return 0;
    if (_t >= 1) return 1;
    return 1 - power(1 - _t, 2);
}

/// Health to show on a card / monster's bar right now
function battlefx_DisplayHealth(_card) {
    if (_card == undefined) return 0;
    if (!variable_struct_exists(_card, "fx_hp_from") || !variable_struct_exists(_card, "fx_blink_start")) return _card.health;
    var _u = battlefx_DrainProgress(_card.fx_blink_start);
    if (_u >= 1) return _card.health;
    return lerp(_card.fx_hp_from, _card.health, _u);
}

/// Health to show on the player's bar right now (_actual = player_health)
function battlefx_HeroDisplayHealth(_actual) {
    battlefx_Init();
    if (global.battlefx_hero_hp_from < 0) return _actual;
    var _u = battlefx_DrainProgress(global.battlefx_hero_blink);
    if (_u >= 1) return _actual;
    return lerp(global.battlefx_hero_hp_from, _actual, _u);
}

function battlefx_HeroBlinkAlpha() {
    battlefx_Init();
    return battlefx_BlinkAlphaFrom(global.battlefx_hero_blink);
}

// ---------------------------------------------------------------------------
// Drawing (called from SCR_Battle_DrawOverlays, above the board)
// ---------------------------------------------------------------------------

function battlefx_Draw() {
    battlefx_Init();
    battlefx_DrawTargetingArrow();

    var _now = current_time;
    for (var i = array_length(global.battle_fx) - 1; i >= 0; i--) {
        var _fx = global.battle_fx[i];
        var _t = _now - _fx.start;
        if (_t < 0) continue;

        switch (_fx.type) {
            case "arrow":
                // grows to the target, stays until the hit lands, then fades
                var _land = variable_struct_exists(_fx, "land") ? _fx.land : BATTLEFX_ARROW_GROW;
                if (_t > _land + BATTLEFX_ARROW_HOLD) { array_delete(global.battle_fx, i, 1); continue; }
                var _grow = clamp(_t / BATTLEFX_ARROW_GROW, 0, 1);
                _grow = 1 - power(1 - _grow, 3);
                var _alpha = (_t < _land) ? 1 : 1 - (_t - _land) / BATTLEFX_ARROW_HOLD;
                battlefx_DrawDashedArrow(_fx.x1, _fx.y1, lerp(_fx.x1, _fx.x2, _grow), lerp(_fx.y1, _fx.y2, _grow), c_red, _alpha);
                break;

            case "bones":
                var _land = sprite_get_number(SPR_FX_Bones) / BATTLEFX_BONES_FPS * 1000;
                if (_t > _land + BATTLEFX_BONES_HOLD + BATTLEFX_BONES_FADE) { array_delete(global.battle_fx, i, 1); continue; }
                var _bf = min(sprite_get_number(SPR_FX_Bones) - 1, floor(_t / 1000 * BATTLEFX_BONES_FPS));
                var _ba = (_t < _land + BATTLEFX_BONES_HOLD) ? 1 : 1 - (_t - _land - BATTLEFX_BONES_HOLD) / BATTLEFX_BONES_FADE;
                draw_sprite_ext(SPR_FX_Bones, _bf, _fx.x, _fx.y, BATTLEFX_BONES_SCALE * _fx.flip, BATTLEFX_BONES_SCALE, 0, c_white, _ba);
                break;

            case "shell":
                // egg shell pieces flying out and falling
                if (_t > 700) { array_delete(global.battle_fx, i, 1); continue; }
                var _u = _t / 700;
                draw_set_alpha(1 - _u * _u);
                for (var k = 0; k < 8; k++) {
                    var _ang = k * 45 + 20;
                    var _px = _fx.x + lengthdir_x(10 + 46 * _u, _ang);
                    var _py = _fx.y + lengthdir_y(10 + 30 * _u, _ang) + 60 * _u * _u;
                    var _r = 5 - k mod 3;
                    var _rot = _u * 400 + k * 40;
                    draw_set_color(make_color_rgb(226, 210, 186));
                    draw_triangle(_px + lengthdir_x(_r, _rot), _py + lengthdir_y(_r, _rot), _px + lengthdir_x(_r, _rot + 130), _py + lengthdir_y(_r, _rot + 130),
                        _px + lengthdir_x(_r, _rot + 240), _py + lengthdir_y(_r, _rot + 240), false);
                    draw_set_color(make_color_rgb(60, 44, 34));
                    draw_triangle(_px + lengthdir_x(_r, _rot), _py + lengthdir_y(_r, _rot), _px + lengthdir_x(_r, _rot + 130), _py + lengthdir_y(_r, _rot + 130),
                        _px + lengthdir_x(_r, _rot + 240), _py + lengthdir_y(_r, _rot + 240), true);
                }
                draw_set_alpha(1);
                draw_set_color(c_white);
                break;

            case "aura":
                if (_t > BATTLEFX_AURA_MS) { array_delete(global.battle_fx, i, 1); continue; }
                battlefx_DrawAura(_fx, _t);
                break;

            case "ghost":
                if (_t > _fx.life_ms) { array_delete(global.battle_fx, i, 1); continue; }
                battlefx_DrawGhost(_fx);
                break;

            case "smoke":
                var _sf = floor(_t / 1000 * BATTLEFX_SMOKE_FPS);
                if (_sf >= sprite_get_number(SPR_FX_Smoke)) { array_delete(global.battle_fx, i, 1); continue; }
                draw_sprite_ext(SPR_FX_Smoke, _sf, _fx.x, _fx.y, 1.15, 1.15, 0, c_white, 1);
                break;

            case "slash":
                var _frame = floor(_t / 1000 * BATTLEFX_SLASH_FPS);
                if (_frame >= sprite_get_number(SPR_FX_Slash)) { array_delete(global.battle_fx, i, 1); continue; }
                draw_sprite_ext(SPR_FX_Slash, _frame, _fx.x, _fx.y, BATTLEFX_SLASH_SCALE * _fx.flip, BATTLEFX_SLASH_SCALE, 0, c_white, 1);
                break;
        }
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// The player is choosing an enemy: arrow from the attacker to the mouse
function battlefx_DrawTargetingArrow() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    var _from = undefined;
    with (_bm) {
        if (!battle_IsPlayerPhase() || !battle_IsTargeting()) return;
        if (string_pos("pick_enemy", target_mode) != 1) return;

        if (pending_player_slot >= 0) {
            _from = battlefx_UnitPos(SIDE_PLAYER, pending_player_slot);
        } else if (pending_monster_slot >= 0) {
            _from = battlefx_UnitPos(SIDE_PLAYER, pending_monster_slot);
        } else {
            var _board = instance_find(OBJ_BoardManager, 0);
            if (_board != noone) _from = { x: _board.action_slot.x + _board.board_card_w / 2, y: _board.action_slot.y + _board.board_card_h / 2 };
        }
    }
    if (_from == undefined) return;

    var _tx = mouse_x;
    var _ty = mouse_y;
    var _color = c_yellow;
    var _enemy = unit_GetSlotAt(SIDE_ENEMY, mouse_x, mouse_y);
    if (_enemy >= 0) {
        var _p = battlefx_UnitPos(SIDE_ENEMY, _enemy);
        _tx = _p.x;
        _ty = _p.y;
        _color = c_red;
    }
    battlefx_DrawDashedArrow(_from.x, _from.y, _tx, _ty, _color, 1);
}

/// Arrow made of one bar sprite "|" repeated along the distance, then the head ">":   ||||||||>
/// One more bar appears for every BATTLEFX_BAR_SPACING pixels dragged.
function battlefx_DrawDashedArrow(_x1, _y1, _x2, _y2, _color, _alpha) {
    var _len = point_distance(_x1, _y1, _x2, _y2);
    if (_len < 6 || _alpha <= 0) return;

    var _dir = point_direction(_x1, _y1, _x2, _y2);
    var _dx = lengthdir_x(1, _dir);
    var _dy = lengthdir_y(1, _dir);
    var _body = max(0, _len - BATTLEFX_HEAD_GAP);
    var _bars = floor(_body / BATTLEFX_BAR_SPACING);

    for (var i = 0; i < _bars; i++) {
        var _d = BATTLEFX_BAR_SPACING * 0.5 + i * BATTLEFX_BAR_SPACING;
        draw_sprite_ext(SPR_FX_ArrowBar, 0, _x1 + _dx * _d, _y1 + _dy * _d, 1, 1, _dir, _color, _alpha);
    }
    draw_sprite_ext(SPR_FX_ArrowHead, 0, _x2, _y2, 1, 1, _dir, _color, _alpha);
}
