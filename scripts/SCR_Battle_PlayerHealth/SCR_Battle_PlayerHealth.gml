/// @desc Player health pool — enemy attacks reduce this; 0 HP = defeat

function battle_InitPlayerHealth() {
    player_max_health = 30;
    player_health = player_max_health;
    battle_lost = false;
}

function battle_GetPlayerHealth() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return 0;
    with (_bm) return player_health;
}

function battle_GetPlayerMaxHealth() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return 0;
    with (_bm) return player_max_health;
}

function battle_IsPlayerDefeated() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) return battle_lost || player_health <= 0;
}

function battle_DamagePlayer(_amount) {
    if (_amount <= 0) return false;
    if (battle_IsPlayerDefeated()) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;

    with (_bm) {
        player_health = max(0, player_health - _amount);
if (player_health <= 0) {
            battle_PlayerDefeat();
        }
    }
    return true;
}

function battle_HealPlayer(_amount) {
    if (_amount <= 0) return false;
    if (battle_IsPlayerDefeated()) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;

    with (_bm) {
        player_health = min(player_max_health, player_health + _amount);
}
    return true;
}

/// @desc Permanently raise max player health (persists across battles). Also heals by the same amount.
function battle_IncreasePlayerMaxHealth(_amount) {
    if (_amount <= 0) return false;

    if (!variable_global_exists("player_max_health")) {
        global.player_max_health = 100;
    }
    global.player_max_health += _amount;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) {
            player_max_health = global.player_max_health;
            player_health = min(player_max_health, player_health + _amount);
        }
    }

return true;
}

function battle_PlayerDefeat() {
    battle_lost = true;
}

function battle_GetPlayerHealthBarRect() {
    return {
        left: 21,
        top: 276,
        right: 282,
        bottom: 290
    };
}

function battle_DrawRoundedHealthBar(_x, _y, _w, _h, _current, _max) {
    var _ratio = (_max > 0) ? clamp(_current / _max, 0, 1) : 0;
    var _rad = _h / 2;

    draw_set_color(c_dkgray);
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, _rad, _rad, false);

    var _fill_w = _w * _ratio;
    if (_fill_w > 0) {
        draw_set_color(c_lime);
        var _fill_rad = min(_rad, _fill_w / 2);
        draw_roundrect_ext(_x, _y, _x + _fill_w, _y + _h, _fill_rad, _fill_rad, false);
    }

    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_x + _w / 2, _y + _h / 2, string(_current) + "/" + string(_max));
    draw_set_valign(fa_top);
}

function battle_DrawPlayerHealthBar() {
    var _rect = battle_GetPlayerHealthBarRect();
    var _bar_w = _rect.right - _rect.left;
    var _bar_h = _rect.bottom - _rect.top;

    battle_DrawRoundedHealthBar(_rect.left, _rect.top, _bar_w, _bar_h, player_health, player_max_health);

    if (battle_lost) {
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(c_red);
        draw_text(_rect.left, _rect.bottom + 4, "Defeat!");
        draw_set_color(c_white);
    }
}
