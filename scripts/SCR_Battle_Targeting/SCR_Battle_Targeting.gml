/// @desc Click targeting for card abilities (JSON traits)



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



function battle_HandleAnyBuffPick(_side, _slot_index) {

    if (pending_trait_source == "monster_on_play") {

        if (battle_ExecuteMonsterOnPlayBuffTrait(pending_monster_slot, pending_monster_trait_index, _side, _slot_index)) {

            battle_MonsterOnPlayContinue(pending_monster_slot, pending_monster_trait_index);

        }

        return;

    }



    if (pending_trait_source == "weapon_on_play") {

        if (battle_ExecuteWeaponOnPlayBuffTrait(pending_weapon_slot, pending_monster_trait_index, _side, _slot_index)) {

            battle_WeaponOnPlayContinue(pending_weapon_slot, pending_monster_trait_index);

        }

        return;

    }



    if (battle_ExecuteActionBuff(pending_action_trait_index, _side, _slot_index)) {

        battle_TargetingContinueAfterAction(pending_action_trait_index);

    }

}



function battle_HandleEnemyTargetPick(_enemy_slot) {

    if (pending_trait_source == "monster_on_play") {

        var _saved_mode = target_mode;

        target_mode = "none";

        if (!battle_ExecuteMonsterOnPlayEnemyTrait(pending_monster_slot, pending_monster_trait_index, _enemy_slot)) {

            target_mode = _saved_mode;

            return;

        }

        battle_MonsterOnPlayContinue(pending_monster_slot, pending_monster_trait_index);

        return;

    }



    if (pending_trait_source == "weapon_on_play") {

        var _saved_weapon_mode = target_mode;

        target_mode = "none";

        if (!battle_ExecuteWeaponOnPlayEnemyTrait(pending_weapon_slot, pending_monster_trait_index, _enemy_slot)) {

            target_mode = _saved_weapon_mode;

            return;

        }

        battle_WeaponOnPlayContinue(pending_weapon_slot, pending_monster_trait_index);

        return;

    }



    switch (target_mode) {

        case "pick_enemy_destroy":

            target_mode = "none";

            if (battle_ExecuteActionDestroy(pending_action_trait_index, _enemy_slot)) {

                battle_TargetingContinueAfterAction(pending_action_trait_index);

            } else {

                target_mode = "pick_enemy_destroy";

            }

            break;

        case "pick_enemy_silence":

            target_mode = "none";

            if (battle_ExecuteActionSilence(pending_action_trait_index, _enemy_slot)) {

                battle_TargetingContinueAfterAction(pending_action_trait_index);

            } else {

                target_mode = "pick_enemy_silence";

            }

            break;

    }

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

        if (pending_trait_source == "action") {
            var _traits = battle_GetActionTraits();
            if (pending_action_trait_index >= 0
                && pending_action_trait_index < array_length(_traits)
                && _traits[pending_action_trait_index].type == "attack_all") {
                if (battle_ExecuteActionAttackAll(pending_action_trait_index, _player_slot)) {
                    battle_TargetingContinueAfterAction(pending_action_trait_index);
                }
                return;
            }
        }

        target_mode = "pick_enemy";

        return;

    }



    if (target_mode == "pick_player_heal") {

        var _heal_slot = battle_GetPlayerMonsterSlotAt(mouse_x, mouse_y);

        if (_heal_slot < 0) return;



        if (pending_trait_source == "monster_on_play") {

            if (battle_ExecuteMonsterOnPlayHealTrait(pending_monster_slot, pending_monster_trait_index, _heal_slot)) {

                battle_MonsterOnPlayContinue(pending_monster_slot, pending_monster_trait_index);

            }

            return;

        }



        if (pending_trait_source == "weapon_on_play") {

            if (battle_ExecuteWeaponOnPlayHealTrait(pending_weapon_slot, pending_monster_trait_index, _heal_slot)) {

                battle_WeaponOnPlayContinue(pending_weapon_slot, pending_monster_trait_index);

            }

            return;

        }



        if (battle_ExecuteActionHeal(pending_action_trait_index, _heal_slot)) {

            battle_TargetingContinueAfterAction(pending_action_trait_index);

        }

        return;

    }



    if (target_mode == "pick_player_self_buff") {

        var _self_buff_slot = battle_GetPlayerMonsterSlotAt(mouse_x, mouse_y);

        if (_self_buff_slot < 0) return;



        if (battle_ExecuteActionSelfBuff(pending_action_trait_index, _self_buff_slot)) {

            battle_TargetingContinueAfterAction(pending_action_trait_index);

        }

        return;

    }



    if (target_mode == "pick_any_buff") {

        var _player_buff_slot = battle_GetPlayerMonsterSlotAt(mouse_x, mouse_y);

        if (_player_buff_slot >= 0) {

            battle_HandleAnyBuffPick("player", _player_buff_slot);

            return;

        }



        var _enemy_buff_slot = battle_GetEnemySlotAt(mouse_x, mouse_y);

        if (_enemy_buff_slot >= 0) {

            battle_HandleAnyBuffPick("enemy", _enemy_buff_slot);

        }

        return;

    }



    if (target_mode == "pick_enemy_destroy"

        || target_mode == "pick_enemy_silence") {

        var _enemy_slot = battle_GetEnemySlotAt(mouse_x, mouse_y);

        if (_enemy_slot < 0) return;

        battle_HandleEnemyTargetPick(_enemy_slot);

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

            battle_TargetingContinueAfterAction(pending_action_trait_index);

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

        var _is_attack_all = false;
        if (pending_trait_source == "action") {
            var _traits = battle_GetActionTraits();
            if (pending_action_trait_index >= 0
                && pending_action_trait_index < array_length(_traits)
                && _traits[pending_action_trait_index].type == "attack_all") {
                _is_attack_all = true;
            }
        }

        if (_is_attack_all) {
            draw_text(room_width / 2, 8, "Choose your monster to attack all enemies");
        } else {
            draw_text(room_width / 2, 8, "Choose your monster card to attack");
        }



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



    if (target_mode == "pick_player_self_buff") {

        draw_text(room_width / 2, 8, "Choose your monster for self buff ATK");



        for (var sb = 0; sb < array_length(_board.player_monster_slots); sb++) {

            var _sbslot = _board.player_monster_slots[sb];

            if (!_sbslot.visible || !_sbslot.occupied) continue;

            draw_set_color(c_aqua);

            draw_rectangle(_sbslot.x, _sbslot.y, _sbslot.x + _sbslot.w, _sbslot.y + _sbslot.h, true);

        }

    }



    if (target_mode == "pick_any_buff") {

        draw_text(room_width / 2, 8, "Choose any monster to buff ATK");

        battle_TargetingDrawPlayerHighlights(_board, c_aqua);

        battle_TargetingDrawEnemyHighlights(_board, c_orange);

    }



    if (target_mode == "pick_enemy_destroy") {

        draw_text(room_width / 2, 8, "Choose an enemy to destroy");

        battle_TargetingDrawEnemyHighlights(_board, c_red);

    }



    if (target_mode == "pick_enemy_silence") {

        draw_text(room_width / 2, 8, "Choose an enemy to silence");

        battle_TargetingDrawEnemyHighlights(_board, c_purple);

    }



    if (target_mode == "pick_enemy") {

        if (pending_trait_source == "weapon") {

            draw_text(room_width / 2, 8, "Choose an enemy to attack with your weapon");

        } else {

            draw_text(room_width / 2, 8, "Choose an enemy to attack");

        }

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

    }



    draw_set_halign(fa_left);

    draw_set_color(c_white);

}



function battle_TargetingDrawPlayerHighlights(_board, _color) {

    draw_set_color(_color);

    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {

        var _slot = _board.player_monster_slots[i];

        if (!_slot.visible || !_slot.occupied || _slot.card == undefined) continue;

        draw_rectangle(_slot.x, _slot.y, _slot.x + _slot.w, _slot.y + _slot.h, true);

    }

}



function battle_TargetingDrawEnemyHighlights(_board, _color) {

    var _mm = instance_find(OBJ_MonsterManager, 0);

    if (_mm == noone) return;



    draw_set_color(_color);

    for (var j = 0; j < _mm.active_slot_count; j++) {

        var _eslot = _board.enemy_slots[j];

        if (!_eslot.visible || !_eslot.occupied) continue;

        var _box = monster_GetHitbox(_eslot);

        draw_rectangle(_box.card_left, _box.card_top, _box.card_right, _box.full_bottom, true);

    }

}

