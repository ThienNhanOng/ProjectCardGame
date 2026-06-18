/// @desc Click targeting for card abilities (JSON traits)

function battle_IsTargeting() {
    return target_mode != "none";
}

function battle_CancelTargeting() {
    target_mode = "none";
    pending_trait_source = "none";
    pending_action_trait_index = -1;
    pending_player_slot = -1;
}

function battle_GetPlayerMonsterSlotAt(_mx, _my) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return -1;

    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
        var _slot = _board.player_monster_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;

        if (_mx >= _slot.x && _mx <= _slot.x + _slot.w &&
            _my >= _slot.y && _my <= _slot.y + _slot.h) {
            return i;
        }
    }
    return -1;
}

function battle_GetEnemySlotAt(_mx, _my) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_board == noone || _mm == noone) return -1;

    for (var i = 0; i < _mm.active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (!_slot.visible || !_slot.occupied || _slot.card == undefined || !_slot.card.alive) continue;

        if (monster_IsMouseOverSlot(_slot)) return i;
    }
    return -1;
}

function battle_TargetingContinueActionTrait(_trait_index, _next_mode) {
    if (battle_CanUseActionTrait(_trait_index) && battle_HasPlayerMonsterOnBoard()) {
        pending_player_slot = -1;
        target_mode = _next_mode;
        return;
    }
    battle_CancelTargeting();
    battle_ClearActionSlotIfFinished();
}

function SCR_Battle_Targeting_Step() {
    if (battle_phase != "player" || !battle_IsTargeting()) return;

    if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
        battle_CancelTargeting();
        return;
    }

    if (!mouse_check_button_pressed(mb_left)) return;

    if (target_mode == "pick_player_monster") {
        var _player_slot = battle_GetPlayerMonsterSlotAt(mouse_x, mouse_y);
        if (_player_slot < 0) return;

        pending_player_slot = _player_slot;
        target_mode = "pick_enemy";
        return;
    }

    if (target_mode == "pick_player_heal") {
        var _heal_slot = battle_GetPlayerMonsterSlotAt(mouse_x, mouse_y);
        if (_heal_slot < 0) return;

        if (battle_ExecuteActionHeal(pending_action_trait_index, _heal_slot)) {
            battle_TargetingContinueActionTrait(pending_action_trait_index, "pick_player_heal");
        }
        return;
    }

    if (target_mode == "pick_enemy") {
        var _enemy_slot = battle_GetEnemySlotAt(mouse_x, mouse_y);
        if (_enemy_slot < 0) return;

        var _ok = false;
        if (pending_trait_source == "weapon") {
            _ok = battle_WeaponAttack(pending_player_slot, _enemy_slot);
            if (_ok) battle_CancelTargeting();
        } else if (battle_ExecuteActionAttack(pending_action_trait_index, pending_player_slot, _enemy_slot)) {
            battle_TargetingContinueActionTrait(pending_action_trait_index, "pick_player_monster");
        }
    }
}

function SCR_Battle_Targeting_Draw() {
    if (!battle_IsTargeting()) return;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    draw_set_halign(fa_center);
    draw_set_color(c_yellow);

    if (target_mode == "pick_player_monster") {
        draw_text(room_width / 2, 8, "Choose your monster card to attack");

        for (var i = 0; i < array_length(_board.player_monster_slots); i++) {
            var _slot = _board.player_monster_slots[i];
            if (!_slot.visible || !_slot.occupied) continue;
            draw_set_color(c_aqua);
            draw_rectangle(_slot.x, _slot.y, _slot.x + _slot.w, _slot.y + _slot.h, true);
        }
    }

    if (target_mode == "pick_player_heal") {
        draw_text(room_width / 2, 8, "Choose your monster card to heal");

        for (var h = 0; h < array_length(_board.player_monster_slots); h++) {
            var _hslot = _board.player_monster_slots[h];
            if (!_hslot.visible || !_hslot.occupied) continue;
            draw_set_color(c_aqua);
            draw_rectangle(_hslot.x, _hslot.y, _hslot.x + _hslot.w, _hslot.y + _hslot.h, true);
        }
    }

    if (target_mode == "pick_enemy") {
        var _prompt = (pending_trait_source == "weapon")
            ? "Choose an enemy to attack"
            : "Choose an enemy to attack";
        draw_text(room_width / 2, 8, _prompt);

        var _mm = instance_find(OBJ_MonsterManager, 0);
        if (_mm != noone) {
            for (var j = 0; j < _mm.active_slot_count; j++) {
                var _eslot = _board.enemy_slots[j];
                if (!_eslot.visible || !_eslot.occupied) continue;
                var _box = monster_GetHitbox(_eslot);
                draw_set_color(c_red);
                draw_rectangle(_box.card_left, _box.card_top, _box.card_right, _box.full_bottom, true);
            }
        }

        if (pending_player_slot >= 0) {
            var _ps = _board.player_monster_slots[pending_player_slot];
            draw_set_color(c_lime);
            draw_rectangle(_ps.x, _ps.y, _ps.x + _ps.w, _ps.y + _ps.h, true);
        }
    }

    draw_set_halign(fa_left);
    draw_set_color(c_white);
}
