/// @desc Example pre-battle dialog for Map1 Marker01

function dialog_Map1_Marker01_PreBattle() {
    return [
        dialog_NameHero("Hero"),
        dialog_NameGuide("Guide"),
        dialog_Left(SPR_Dialog_Player, "hero", true),
        dialog_Right(SPR_Dialog_Testcharacter, "guide", true),
        dialog_LineKey("hero", "The trail starts here. Ready?"),
        dialog_LineKey("guide", "Stay sharp — a colorsentence(blue,\"Advance Strike\") could help."),
        dialog_LineKey("hero", "Let's go."),
        dialog_Left(SPR_Dialog_Testcharacter, "hero", true),
        dialog_HideRight(),
        dialog_LineKey("hero", "battle time"),

        dialog_Background(SPR_BG_GrassTest, true),
        dialog_LineKey("hero", "image change"),

        dialog_ShowRight(),
        dialog_LineKey("guide", "Stay sharp — a colorsentence(blue,\"Advance Strike\") could help."),
        dialog_LineKey("hero", "Let's go.")
    ];
}

function dialog_Map1_Marker01_PostBattle() {
    return [
        dialog_Background(SPR_BG_GrassTest, true),
        dialog_NameHero("Hero"),
        dialog_NameGuide("Guide"),
        dialog_Left(SPR_Dialog_Player, "hero", true),
        dialog_Right(SPR_Dialog_Testcharacter, "guide", true),
        dialog_LineKey("hero", "We made it through!"),
        dialog_LineKey("guide", "Keep moving — more battles ahead."),
        dialog_ClearChars()
    ];
}
