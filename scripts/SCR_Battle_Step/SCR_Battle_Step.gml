/// @desc Battle input — card abilities use click targeting only

function SCR_Battle_Step() {
    if (battle_phase != "player") return;
    SCR_Battle_Targeting_Step();
}
