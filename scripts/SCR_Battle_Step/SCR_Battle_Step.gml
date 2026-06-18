/// @desc Battle input — targeting + End Turn button

function SCR_Battle_Step() {
    if (battle_IsPlayerPhase()) {
        SCR_Battle_Targeting_Step();
        if (!battle_IsTargeting()) {
            SCR_Battle_WeaponInput_Step();
            battle_HandleEndTurnButton();
        }
    }
}
