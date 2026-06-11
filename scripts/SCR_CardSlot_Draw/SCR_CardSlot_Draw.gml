function SCR_CardSlot_Draw() {
    if (!SCR_CardSlot_CheckVisibility()) exit;
    if (card_data == undefined) exit;
    
    // 1. Draw background (bottom layer)
    SCR_CardSlot_DrawBackground();
    
    // 2. Draw picture (on top of background)
    SCR_CardSlot_DrawPicture();
    
    // 3. Draw text (on top of picture)
    SCR_CardSlot_DrawText();
    
    // 4. Draw level (on top of text)
    SCR_CardSlot_DrawLevel();
    
    // 5. Draw badge (TOP LAYER - last drawn)
    SCR_CardSlot_DrawCountBadge();
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}