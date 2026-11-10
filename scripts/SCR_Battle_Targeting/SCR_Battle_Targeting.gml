/// @desc Player click-targeting for card abilities and column attacks. Runs on OBJ_BattleManager.
///
/// target_mode says what the next click picks:
///   pick_player_monster   attacker for an action attack / attack_all
///   pick_player_heal      player monster to heal
///   pick_player_self_buff player monster to buff
///   pick_any_buff         any monster (player or enemy) to buff
///   pick_enemy            enemy to attack (action attack or weapon/column strike)
///   pick_enemy_destroy    enemy to destroy
///   pick_enemy_silence    enemy to silence
///   pick_player_effect / pick_any_effect / pick_enemy_effect
///                         target for any other single-target trait (e.g. "damage", or JSON "target")
///   pick_free_spot        an empty, open monster spot of yours to summon into

function battle_IsTargeting() {
    return target_mode != "none";
}

function battle_CancelTargeting() {
    target_mode = "none";
    pending_trait_source = "none";
    pending_action_trait_index = -1;
    pending_player_slot = -1;
    pending_monster_slot = -1;
    pending_monster_trait_index = -1;
    pending_weapon_slot = -1;
}

// ---------------------------------------------------------------------------
// Clicks
// ---------------------------------------------------------------------------

function SCR_Battle_Targeting_Step() {
    if (!battle_IsPlayerPhase() || !battle_IsTargeting()) return;

    if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
        battle_CancelCurrentAction();
        return;
    }

    if (!mouse_check_button_pressed(mb_left)) return;

    if (target_mode == "pick_free_spot") {
        var _spot = -1;
        with (instance_find(OBJ_BoardManager, 0)) _spot = SCR_Board_MonsterSlotAt(mouse_x, mouse_y, false);
        if (_spot >= 0) battle_TargetingClickFreeSpot(_spot);
        return;
    }

    var _player_slot = unit_GetSlotAt(SIDE_PLAYER, mouse_x, mouse_y);
    if (_player_slot >= 0 && battle_TargetingAcceptsPlayerSlot()) {
        battle_TargetingClickPlayerSlot(_player_slot);
        return;
    }

    var _enemy_slot = unit_GetSlotAt(SIDE_ENEMY, mouse_x, mouse_y);
    if (_enemy_slot >= 0) {
        battle_TargetingClickEnemySlot(_enemy_slot);
    }
}

/// True when the current mode is answered by clicking one of the player's monsters
function battle_TargetingAcceptsPlayerSlot() {
    return target_mode == "pick_player_monster"
        || target_mode == "pick_player_heal"
        || target_mode == "pick_player_self_buff"
        || target_mode == "pick_player_effect"
        || target_mode == "pick_any_buff"
        || target_mode == "pick_any_effect";
}

/// Does the current pick deal damage? (weapon strikes, action attacks, "damage" effects)
/// Units guarded by a frontline can't be picked for those.
function battle_TargetingDealsDamage() {
    if (target_mode == "pick_enemy") return true;
    if (target_mode == "pick_player_monster") return false;   // choosing the attacker, not the victim
    var _info = battle_GetPendingTraitInfo();
    return _info != undefined && (_info.trait.effect == "damage" || _info.trait.effect == "attack");
}

/// Can the unit in _slot be picked by the current target mode? (frontline guard check)
function battle_TargetingCanPick(_side, _slot) {
    return !(battle_TargetingDealsDamage() && unit_IsGuarded(_side, _slot));
}

/// The player clicked their monster in _slot while targeting
function battle_TargetingClickPlayerSlot(_slot) {
    if (!battle_IsPlayerPhase() || !battle_IsTargeting()) return;
    if (!unit_IsAlive(SIDE_PLAYER, _slot)) return;
    if (!battle_TargetingCanPick(SIDE_PLAYER, _slot)) return;

    switch (target_mode) {
        case "pick_player_monster":
            if (battle_IsPlayerMonsterSlotShrouded(_slot)) return;
            pending_player_slot = _slot;

            var _info = battle_GetPendingTraitInfo();
            if (pending_trait_source == "action" && _info != undefined && _info.trait.type == "attack_all") {
                if (battle_ExecuteActionAttack("attack_all")) {
                    battle_TargetingContinueAfterAction(pending_action_trait_index);
                }
                return;
            }
            target_mode = "pick_enemy";
            return;

        case "pick_player_heal":
        case "pick_player_self_buff":
        case "pick_player_effect":
        case "pick_any_buff":
        case "pick_any_effect":
            battle_ResolvePendingTrait(targets_Single(SIDE_PLAYER, _slot));
            return;
    }
}

/// The player clicked an empty spot of theirs while a summon waits for one
function battle_TargetingClickFreeSpot(_spot) {
    if (!battle_IsPlayerPhase() || target_mode != "pick_free_spot") return;
    if (!battle_IsFreeMonsterSpot(_spot)) return;
    battle_ResolvePendingTrait(targets_Single(SIDE_PLAYER, _spot));
}

/// True while a summon waits for the player to click a free spot
function battle_IsPickingSummonSpot() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    return _bm != noone && _bm.target_mode == "pick_free_spot";
}

/// The player clicked the enemy in _slot while targeting
function battle_TargetingClickEnemySlot(_slot) {
    if (!battle_IsPlayerPhase() || !battle_IsTargeting()) return;
    if (!unit_IsAlive(SIDE_ENEMY, _slot)) return;
    if (!battle_TargetingCanPick(SIDE_ENEMY, _slot)) return;   // behind a frontline

    switch (target_mode) {
        case "pick_any_buff":
        case "pick_any_effect":
        case "pick_enemy_destroy":
        case "pick_enemy_silence":
        case "pick_enemy_effect":
            battle_ResolvePendingTrait(targets_Single(SIDE_ENEMY, _slot));
            return;

        case "pick_enemy":
            if (pending_trait_source == "weapon") {
                if (battle_ColumnAttack(pending_player_slot, _slot)) battle_CancelTargeting();
                return;
            }
            if (battle_ExecuteActionAttack("attack", targets_Single(SIDE_ENEMY, _slot))) {
                battle_TargetingContinueAfterAction(pending_action_trait_index);
            }
            return;
    }
}

function battle_GetPendingTraitText() {
    var _info = battle_GetPendingTraitInfo();
    return (_info == undefined) ? "" : trait_GetDisplayText(_info.trait);
}

/// Card the player can pick on their side: hand first (if _include_hand), then action, weapons, monsters
function battle_FindPlayerCardAt(_mx, _my, _include_hand) {
    if (_include_hand) {
        var _hand_card = battle_FindHandCardAt(_mx, _my);
        if (_hand_card != undefined) return _hand_card;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return undefined;

    var _found = undefined;
    with (_board) {
        // a weapon shows as a chip on its monster's card
        _found = SCR_Board_WeaponChipAt(_mx, _my);

        // the top-most of your units under the point (they can overlap)
        if (_found == undefined) {
            var _unit = unit_GetSlotAt(SIDE_PLAYER, _mx, _my);
            if (_unit >= 0) _found = player_monster_slots[_unit].card;
        }

        if (_found == undefined && action_slot.visible && action_slot.occupied && action_slot.card != undefined
            && SCR_Board_IsSlotMouseOver(action_slot)) {
            _found = action_slot.card;
        }
    }
    return _found;
}

function battle_FindHandCardAt(_mx, _my) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone || _hand.hand_Count <= 0) return undefined;

    var _spacing = SCR_Hand_GetSpacing(_hand.hand_Count, 5);
    var _idx = SCR_Hand_PickCardIndex(_mx, _my, _hand.hand_Count, _spacing, _hand.hand_Y);
    if (_idx >= 0) return _hand.hand[_idx];
    return undefined;
}

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

function SCR_Battle_Targeting_Draw() {
    if (!battle_IsTargeting()) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    draw_set_halign(fa_center);
    draw_set_color(c_yellow);

    switch (target_mode) {
        case "pick_player_monster":
            var _info = battle_GetPendingTraitInfo();
            var _is_attack_all = pending_trait_source == "action" && _info != undefined && _info.trait.type == "attack_all";
            draw_text(room_width / 2, 8, _is_attack_all
                ? "Choose your monster to attack all enemies"
                : "Choose your monster card to attack");
            battle_TargetingDrawPlayerHighlights(_board, c_aqua, true);
            break;

        case "pick_player_heal":
            draw_text(room_width / 2, 8, "Choose your monster card to heal");
            battle_TargetingDrawPlayerHighlights(_board, c_aqua, false);
            break;

        case "pick_player_self_buff":
            draw_text(room_width / 2, 8, "Choose your monster for self buff ATK");
            battle_TargetingDrawPlayerHighlights(_board, c_aqua, false);
            break;

        case "pick_player_effect":
            draw_text(room_width / 2, 8, "Choose your monster: " + battle_GetPendingTraitText());
            battle_TargetingDrawPlayerHighlights(_board, c_aqua, false);
            break;

        case "pick_any_effect":
            draw_text(room_width / 2, 8, "Choose any monster: " + battle_GetPendingTraitText());
            battle_TargetingDrawPlayerHighlights(_board, c_aqua, false);
            battle_TargetingDrawEnemyHighlights(_board, c_orange);
            break;

        case "pick_enemy_effect":
            draw_text(room_width / 2, 8, "Choose an enemy: " + battle_GetPendingTraitText());
            battle_TargetingDrawEnemyHighlights(_board, c_red);
            break;

        case "pick_any_buff":
            draw_text(room_width / 2, 8, "Choose any monster to buff ATK");
            battle_TargetingDrawPlayerHighlights(_board, c_aqua, false);
            battle_TargetingDrawEnemyHighlights(_board, c_orange);
            break;

        case "pick_enemy_destroy":
            draw_text(room_width / 2, 8, "Choose an enemy to destroy");
            battle_TargetingDrawEnemyHighlights(_board, c_red);
            break;

        case "pick_enemy_silence":
            draw_text(room_width / 2, 8, "Choose an enemy to silence");
            battle_TargetingDrawEnemyHighlights(_board, c_purple);
            break;

        case "pick_free_spot":   // the free spots themselves light up in SCR_Board_DrawEmptyZones
            var _summon_info = battle_GetPendingTraitInfo();
            var _summon_name = (_summon_info != undefined) ? deck_GetCardName(_summon_info.trait.card_id) : "a monster";
            draw_text(room_width / 2, 8, "Choose a free spot to summon " + _summon_name);
            break;

        case "pick_enemy":
            draw_text(room_width / 2, 8, (pending_trait_source == "weapon")
                ? "Choose an enemy to attack with your weapon"
                : "Choose an enemy to attack");
            battle_TargetingDrawEnemyHighlights(_board, c_red);

            if (pending_player_slot >= 0) {
                var _ps = _board.player_monster_slots[pending_player_slot];
                draw_set_color(c_lime);
                draw_rectangle(_ps.x, _ps.y, _ps.x + _ps.w, _ps.y + _ps.h, true);

                if (pending_trait_source == "weapon") {
                    var _ws = _board.player_weapon_slots[pending_player_slot];
                    if (_ws.visible && _ws.occupied) {
                        draw_set_color(c_yellow);
                        draw_rectangle(_ws.x, _ws.y, _ws.x + _ws.w, _ws.y + _ws.h, true);
                    }
                }
            }
            break;
    }

    draw_set_halign(fa_left);
    draw_set_color(c_white);
}

/// Outline the player's monsters (optionally skipping shrouded ones that cannot attack)
function battle_TargetingDrawPlayerHighlights(_board, _color, _skip_shrouded) {
    draw_set_color(_color);
    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;
        if (_skip_shrouded && battle_IsPlayerMonsterSlotShrouded(i)) continue;
        if (!battle_TargetingCanPick(SIDE_PLAYER, i)) continue;
        draw_rectangle(_slot.x, _slot.y, _slot.x + _slot.w, _slot.y + _slot.h, true);
    }
}

function battle_TargetingDrawEnemyHighlights(_board, _color) {
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_mm == noone) return;

    // a pulsing ring on each target's pedestal; the one under the mouse is bold
    var _hover = unit_GetSlotAt(SIDE_ENEMY, mouse_x, mouse_y);
    draw_set_color(_color);
    for (var j = 0; j < array_length(_board.enemy_slots); j++) {
        var _eslot = _board.enemy_slots[j];
        if (!_eslot.visible || !_eslot.occupied) continue;
        if (!battle_TargetingCanPick(SIDE_ENEMY, j)) continue;   // guarded by a frontline: not a target
        var _f = battle_LayoutEnemyFeet(j);
        var _bold = (j == _hover);
        draw_set_alpha(_bold ? 1 : 0.45 + 0.35 * sin(current_time / 170));
        for (var k = 0; k < (_bold ? 4 : 2); k++) draw_ellipse(_f.x - 56 - k, _f.y - 15 - k, _f.x + 56 + k, _f.y + 15 + k, true);
    }
    draw_set_alpha(1);
}
