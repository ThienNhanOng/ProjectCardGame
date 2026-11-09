/// @desc Battle hit effects: the dashed targeting arrow, enemy attack arrows, the sword-swing slash and the hit blink.
///
/// - While you pick an enemy to hit, a dashed arrow runs from your attacker to the mouse
///   (it snaps to and turns red over a valid enemy).
/// - Every hit (combat_DamageUnit) plays SPR_FX_Slash on the target and makes it blink for a second,
///   while its health bar drains smoothly from the old value to the new one (display only).
/// - An enemy attack first shoots a dashed arrow to its target; when the arrow arrives the enemy plays its
///   attack animation, and the slash + blink + health drain land at the animation's strike moment.
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

    array_push(global.battle_fx, { type: "slash", x: _pos.x, y: _pos.y, start: _start });

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

/// A unit dies: its bones drop where it stood and fade away
function battlefx_Death(_side, _slot) {
    battlefx_Init();
    var _f = battlefx_UnitFeet(_side, _slot);
    if (_f == undefined) return;
    array_push(global.battle_fx, { type: "bones", x: _f.x, y: _f.y, start: current_time + global.battlefx_hit_delay,
        flip: (_side == SIDE_ENEMY) ? -1 : 1 });
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
///   1. dashed arrows grow to the targets (BATTLEFX_ARROW_GROW)
///   2. then the enemy's attack animation starts
///   3. the hits (slash, blink, health drain) land BATTLEFX_STRIKE_MS into that animation
function battlefx_EnemyAttack(_enemy_slot, _targets) {
    battlefx_Init();
    var _from = battlefx_UnitPos(SIDE_ENEMY, _enemy_slot);
    if (_from == undefined) return;
    var _land = BATTLEFX_ARROW_GROW + BATTLEFX_STRIKE_MS;
    for (var i = 0; i < array_length(_targets); i++) {
        var _to = battlefx_UnitPos(_targets[i].side, _targets[i].slot);
        if (_to == undefined) continue;
        array_push(global.battle_fx, { type: "arrow", x1: _from.x, y1: _from.y + 20, x2: _to.x, y2: _to.y, start: current_time, land: _land });
    }
    monsterAnim_PlayAttack(unit_Get(SIDE_ENEMY, _enemy_slot), BATTLEFX_ARROW_GROW);
    global.battlefx_hit_delay = _land;
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

            case "smoke":
                var _sf = floor(_t / 1000 * BATTLEFX_SMOKE_FPS);
                if (_sf >= sprite_get_number(SPR_FX_Smoke)) { array_delete(global.battle_fx, i, 1); continue; }
                draw_sprite_ext(SPR_FX_Smoke, _sf, _fx.x, _fx.y, 1.15, 1.15, 0, c_white, 1);
                break;

            case "slash":
                var _frame = floor(_t / 1000 * BATTLEFX_SLASH_FPS);
                if (_frame >= sprite_get_number(SPR_FX_Slash)) { array_delete(global.battle_fx, i, 1); continue; }
                draw_sprite_ext(SPR_FX_Slash, _frame, _fx.x, _fx.y, BATTLEFX_SLASH_SCALE, BATTLEFX_SLASH_SCALE, 0, c_white, 1);
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
