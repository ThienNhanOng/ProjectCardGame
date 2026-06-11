function SCR_DBD_Draw() {
    SCR_DBD_DrawContainer();
    SCR_DBD_DrawDeckInfo();
    SCR_DBD_DrawDeckList();
    
    // Reset drawing settings
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}