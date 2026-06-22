/// @desc Battle input — targeting + End Turn button

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

    worldmap_BattleVictoryStep();

    if (battle_IsPlayerPhase()) {
        if (!battle_ConsumeSkipFollowUpInput()) {
            SCR_Battle_Targeting_Step();
            if (!battle_IsTargeting()) {
                SCR_Battle_WeaponInput_Step();
                battle_HandleEndTurnButton();
            }
        }
    }
}
