/// @desc OBJ_BattleManager entry points — Create / Step / Draw

function SCR_Battle_Init() {
    battle_ApplyBackground();   // this map's / battle's battlefield (scr_battle_layout)

    battle_phase = "player";

    turn_number = 1;

    weapon_attacks_used = [0, 0, 0, 0, 0];

    action_trait_uses = [];
    action_card_used = false;

    target_mode = "none";

    pending_trait_source = "none";

    pending_action_trait_index = -1;

    pending_player_slot = -1;

    pending_monster_slot = -1;

    pending_monster_trait_index = -1;

    pending_weapon_slot = -1;

    battle_InitPlayerHealth();

    battle_InitResources();

    battle_SpiritShuffle_Init();

    conditions_summon_Reset();

    battle_skip_followup_input = false;

    trait_chain_added_cards = [];
    trait_chain_added_deck_ids = [];
    trait_pending_add_cost_entries = [];
    trait_chain_deck_id_costs = {};

    battle_InitZoneOwners();

    battle_PrepareBoardCards();

    battle_EnemyTurn_Init();

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

function battle_SkipFollowUpInputThisFrame() {
    battle_skip_followup_input = true;
}

function battle_ConsumeSkipFollowUpInput() {
    if (!battle_skip_followup_input) return false;
    battle_skip_followup_input = false;
    return true;
}

function SCR_Battle_Step() {
    if (battle_IsPlayerDefeated()) return;

    battle_EnemyLog_Step();

    var _bm = instance_find(OBJ_BattleManager, 0);
    var _deck = instance_find(OBJ_Deck, 0);

    if (_deck != noone) {
        with (_deck) deck_ExtraDeck_Step();
    }

    if (_bm != noone) {
        with (_bm) conditions_summon_Step();
    }

    if (_bm != noone) {
        with (_bm) {
            if (conditions_summon_IsActive()) return;
        }
    }

    if (_deck != noone) {
        with (_deck) {
            if (deck_AnyPickerOpen()) return;
        }
    }

    if (battle_SpiritShuffle_IsActive()) {
        battle_SpiritShuffle_Step();
        return;
    }

    worldmap_BattleVictoryStep();
    if (worldmap_IsBattleWon()) return;   // battle over: no more card play / end turn

    if (battle_IsPlayerPhase()) {
        if (!battle_ConsumeSkipFollowUpInput()) {
            SCR_Battle_Targeting_Step();
            if (!battle_IsTargeting()) {
                SCR_Battle_WeaponInput_Step();
                battle_HandleEndTurnButton();
            }
        }
        return;
    }

    if (battle_IsEnemyPhase()) {
        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) {
                if (monsterAbility_picker_active) {
                    monsterAbility_Picker_Step();
                    return;
                }
            }
        }
        battle_EnemyTurn_Step();
    }
}

function SCR_Battle_Draw() {
    SCR_Battle_UI_Draw();

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.action_slot.occupied && _board.action_slot.card != undefined) {
        var _x = _board.action_slot.x + _board.action_slot.w + 10;
        var _y = _board.action_slot.y;
        var _card = _board.action_slot.card;
        var _traits = battle_GetActionTraits();

        draw_set_color(c_white);
        draw_text(_x, _y, _card.name);

        for (var i = 0; i < array_length(_traits); i++) {
            var _uses_left = (i < array_length(action_trait_uses)) ? action_trait_uses[i] : 0;
            draw_text(_x, _y + 20 + i * 14,
                trait_GetDisplayText(_traits[i]) + "  x" + string(_uses_left));
        }
    }

    SCR_Battle_Targeting_Draw();

    draw_set_color(c_white);
}

function SCR_Battle_DrawOverlays() {
    battlefx_Draw();   // targeting arrow, attack arrows, sword swings
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck != noone) {
        with (_deck) deck_ExtraDeckPicker_Draw();
    }

    battle_EnemyLog_DrawPanel();

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) {
            conditions_summon_Draw();
            monsterAbility_Picker_Draw();
            battle_SpiritShuffle_Draw();
        }
    }

    battle_DrawHoverPreview();

    debug_DrawMouseCoordinates();

    draw_set_color(c_white);
}
