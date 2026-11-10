/// @desc Player column attacks — a monster column (monster + weapon below it) strikes once per turn
/// (weapons can grant more strikes). Damage = monster attack + weapon attack + buffs (scr_combat).
/// Only armed columns strike: a weapon is equipped, or the monster is an extra-deck spirit.
/// Runs on OBJ_BattleManager. Damage goes through card_Damage.

function battle_GetColumnAttackRecursion(_column) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return 1;
    if (_column < 0 || _column >= array_length(_board.player_weapon_slots)) return 1;

    var _monster_slot = _board.player_monster_slots[_column];
    var _weapon_slot = _board.player_weapon_slots[_column];

    if (_weapon_slot.visible && _weapon_slot.occupied && _weapon_slot.card != undefined) {
        if (_monster_slot.visible && _monster_slot.occupied && _monster_slot.card != undefined
            && card_IsSpiritType(_monster_slot.card)) {
            return 1;
        }
        return weapon_GetAttackRecursion(_weapon_slot.card);
    }
    return 1;
}

function battle_GetColumnAttackUsesLeft(_column) {
    if (_column < 0 || _column >= array_length(weapon_attacks_used)) return 0;
    return max(0, battle_GetColumnAttackRecursion(_column) - weapon_attacks_used[_column]);
}

function battle_ConsumeColumnAttack(_column) {
    if (_column < 0 || _column >= array_length(weapon_attacks_used)) return;
    weapon_attacks_used[_column]++;
}

function battle_CanColumnAttack(_column) {
    if (!battle_IsPlayerPhase()) return false;
    if (_column < 0 || _column >= array_length(weapon_attacks_used)) return false;
    if (battle_GetColumnAttackUsesLeft(_column) <= 0) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _board.is_dragging) return false;

    var _monster = unit_Get(SIDE_PLAYER, _column);
    if (_monster == undefined) return false;
    if (status_IsShrouded(_monster)) return false;

    // a monster needs a weapon to strike from its column (action cards are separate); spirits don't
    var _parts = battle_GetColumnStrikeParts(_column);
    if (!_parts.armed) return false;
    if (_parts.weapon_attack_all > 0 || _parts.monster_attack_all > 0) return true;
    return _parts.monster_strike + _parts.weapon_strike > 0;
}

/// Click on a column: attack_all columns hit immediately, single strikes wait for an enemy pick
function battle_BeginColumnAttack(_column) {
    if (battle_IsTargeting()) return false;
    if (!battle_CanColumnAttack(_column)) return false;

    var _parts = battle_GetColumnStrikeParts(_column);

    battle_CancelTargeting();

    if (_parts.weapon_attack_all > 0) {
        return battle_ColumnAttackAll(_column, battle_ColumnWeaponAttackAllTotal(_parts));
    }

    if (_parts.monster_attack_all > 0) {
        return battle_ColumnAttackAll(_column, battle_ColumnMonsterAttackAllTotal(_parts));
    }

    if (_parts.monster_strike + _parts.weapon_strike > 0) {
        pending_trait_source = "weapon";
        pending_action_trait_index = -1;
        pending_player_slot = _column;
        target_mode = "pick_enemy";
        return true;
    }

    return false;
}

function battle_ColumnAttackAll(_column, _amount) {
    if (!battle_CanColumnAttack(_column)) return false;
    if (_amount <= 0) return false;

    var _targets = targets_All(SIDE_ENEMY);
    battlefx_PlayerAttack(_column, _targets);   // runs up to the group; the blows land when it arrives
    var _ok = card_Damage(effect_Source(SIDE_PLAYER, _column), _targets, _amount);
    battlefx_EndDelay();
    if (_ok) battle_ConsumeColumnAttack(_column);
    return _ok;
}

/// Single strike from a column on one enemy
function battle_ColumnAttack(_column, _enemy_slot) {
    if (!battle_CanColumnAttack(_column)) return false;

    var _amount = battle_ColumnSingleStrikeTotal(battle_GetColumnStrikeParts(_column));
    if (_amount <= 0) return false;

    var _targets = targets_Single(SIDE_ENEMY, _enemy_slot);
    battlefx_PlayerAttack(_column, _targets);   // runs up to the enemy; the blow lands when it arrives
    var _ok = card_Damage(effect_Source(SIDE_PLAYER, _column), _targets, _amount);
    battlefx_EndDelay();
    if (_ok) battle_ConsumeColumnAttack(_column);
    return _ok;
}

/// Column under the mouse that can attack, or -1. The weapon sits on its monster's card, so this is
/// the top-most unit under the point (units can overlap) — when that one can't attack, nothing does.
function battle_GetAttackColumnAt(_mx, _my) {
    var _column = unit_GetSlotAt(SIDE_PLAYER, _mx, _my);
    if (_column < 0 || !battle_CanColumnAttack(_column)) return -1;
    return _column;
}

function SCR_Battle_WeaponInput_Step() {
    if (!battle_IsPlayerPhase() || battle_IsTargeting()) return;
    if (!mouse_check_button_pressed(mb_left)) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || _board.is_dragging) return;

    var _column = battle_GetAttackColumnAt(mouse_x, mouse_y);
    if (_column < 0) return;

    battle_BeginColumnAttack(_column);
}
