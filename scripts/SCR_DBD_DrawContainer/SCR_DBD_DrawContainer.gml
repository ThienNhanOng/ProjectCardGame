function SCR_DBD_DrawContainer() {
    // Container background
    draw_set_color(c_black);
    draw_set_alpha(0.3);
    draw_rectangle(container_x, container_y, container_x + container_w, container_y + container_h, false);
    draw_set_alpha(1);
    
    // Container border
    draw_set_color(c_white);
    draw_rectangle(container_x, container_y, container_x + container_w, container_y + container_h, true);
    
    // Label
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(container_x, container_y - 20, "Card Collection");
    
    // Page info - FIXED: Use player collection
    var _total_pages = SCR_DBD_GetCollectionPageCount(cards_per_page);
    
    draw_set_color(c_white);
    draw_set_halign(fa_right);
    draw_text(container_x + container_w - 10, container_y - 20, "Page " + string(current_page + 1) + "/" + string(_total_pages));
    draw_set_halign(fa_left);
}