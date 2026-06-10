function SCR_CardSlot_Draw() {
    if (!SCR_CardSlot_CheckVisibility()) exit;
    if (card_data == undefined) exit;
    
    SCR_CardSlot_DrawBackground();  // 1. Draw background first
    SCR_CardSlot_DrawPicture();      // 2. Draw image on background
    SCR_CardSlot_DrawText();         // 3. Draw text ON TOP of image
    SCR_CardSlot_DrawLevel();        // 4. Draw level on top
    SCR_CardSlot_DrawCountBadge();   // 5. Draw badge on top
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}