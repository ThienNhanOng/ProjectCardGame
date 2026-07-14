/// @desc Example pre-battle dialog for Map1 Marker01

function dialog_Map1_Marker01_PreBattle() {
    return [
        dialog_LeftName("Hero"),
        dialog_RightName("Guide"),
        //dialog_Left(SPR_Dialog_Player),
        //dialog_Right(SPR_Dialog_Testcharacter),
		
        dialog_LeftLine(""),
        dialog_RightLine("Stay sharp — a colorsentence(blue,\"Advance Strike\") could help."),
        dialog_LeftLine("Let's go."),
        dialog_Left(SPR_Dialog_Testcharacter),
        dialog_HideRight(),
        dialog_LeftLine("battle time"),

        dialog_Background(SPR_BG_GrassTest, true),
        dialog_LeftLine("image change"),

        dialog_ShowRight(),
        dialog_RightLine("Stay sharp — a colorsentence(blue,\"Advance Strike\") could help."),
        dialog_LeftLine("Let's go.")
    ];
}

function dialog_Map1_Marker01_PostBattle() {
    return [
        dialog_Background(SPR_BG_GrassTest, true),
        dialog_LeftName("Hero"),
        dialog_RightName("Guide"),
        dialog_Left(SPR_Dialog_Player),
        dialog_Right(SPR_Dialog_Testcharacter),
        dialog_LeftLine("We made it through!"),
        dialog_RightLine("Keep moving — more battles ahead."),
        dialog_ClearChars()
    ];
}

function dialog_Map1_Marker02_PreBattle() {
    return [
        dialog_LeftName("Player"),
        dialog_RightName("A"),
        dialog_Left(SPR_Dialog_Player),
        dialog_Right(SPR_Dialog_Testcharacter),
        dialog_RightLine("Crossroads ahead. Win here and the path opens to Map 2."),
        dialog_LeftLine("Got it."),
        dialog_RightName("B"),
        dialog_RightLine("Keep your guard up."),
        dialog_LeftLine("Always."),
    ];
}

function dialog_Map1_Marker05_PreBattle() {
    return [
        dialog_LeftName("Guide"),
        dialog_LeftLine("The gate is guarded. Clear this fight to reach Map 2."),
    ];
}
