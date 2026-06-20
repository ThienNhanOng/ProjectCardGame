/// @desc OBJ_BattleManager Create entry point



function SCR_Battle_Init() {

    battle_phase = "player";

    turn_number = 1;

    weapon_attacks_used = [0, 0, 0, 0, 0];

    action_trait_uses = [];

    target_mode = "none";

    pending_trait_source = "none";

    pending_action_trait_index = -1;

    pending_player_slot = -1;

    pending_monster_slot = -1;

    pending_monster_trait_index = -1;

    pending_weapon_slot = -1;

    battle_InitPlayerHealth();

    conditions_summon_Reset();

    battle_InitZoneOwners();

    battle_PrepareBoardCards();

    battle_StartBattle();
}



function battle_PrepareBoardCards() {

    var _board = instance_find(OBJ_BoardManager, 0);

    if (_board == noone) return;



    for (var i = 0; i < array_length(_board.player_monster_slots); i++) {

        var _slot = _board.player_monster_slots[i];

        if (_slot.occupied && _slot.card != undefined) {

            battle_EnsureCardHealth(_slot.card);

        }

    }

}



function battle_RefreshActionUses() {

    action_trait_uses = [];



    var _board = instance_find(OBJ_BoardManager, 0);

    if (_board == noone || !_board.action_slot.occupied || _board.action_slot.card == undefined) return;



    var _traits = trait_GetFromCard(_board.action_slot.card);

    for (var i = 0; i < array_length(_traits); i++) {
        if (trait_IsRepeatable(_traits[i])) {
            array_push(action_trait_uses, trait_GetRecursionLimit(_traits[i]));
        } else {
            array_push(action_trait_uses, 0);
        }
    }

}



function battle_GetHoveredEnemySlot() {

    var _mm = instance_find(OBJ_MonsterManager, 0);

    if (_mm == noone) return 0;

    if (_mm.hovered_enemy_slot >= 0) return _mm.hovered_enemy_slot;

    return 0;

}


