/// @desc Battle input — targeting + End Turn button

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

    if (battle_IsPlayerPhase()) {
        SCR_Battle_Targeting_Step();
        if (!battle_IsTargeting()) {
            SCR_Battle_WeaponInput_Step();
            battle_HandleEndTurnButton();
        }
    }
}
