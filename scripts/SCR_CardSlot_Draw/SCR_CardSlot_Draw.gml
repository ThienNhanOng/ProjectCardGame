function SCR_CardSlot_Draw() {
    if (!SCR_CardSlot_CheckVisibility()) exit;
    if (card_data == undefined) exit;
    
    // Get hover transform from imported function
    var _transform = SCR_DeckHover_GetTransform(x, y, card_w, card_h);
    
    // Draw glow effect
    SCR_DeckHover_DrawGlow(_transform.draw_x, _transform.draw_y, _transform.w, _transform.h, _transform.is_hovered);
    
    // If hovered, we need to temporarily move the card for drawing
    if (_transform.is_hovered) {
        // Store original position
        var _orig_x = x;
        var _orig_y = y;
        var _orig_w = card_w;
        var _orig_h = card_h;
        
        // Temporarily change card position for drawing
        x = _transform.draw_x;
        y = _transform.draw_y;
        card_w = _transform.w;
        card_h = _transform.h;
        
        // Draw with new position
        SCR_CardSlot_DrawBackground();
        SCR_CardSlot_DrawPicture();
        SCR_CardSlot_DrawText();
        SCR_CardSlot_DrawLevel();
        SCR_CardSlot_DrawCountBadge();
        
        // Restore original values
        x = _orig_x;
        y = _orig_y;
        card_w = _orig_w;
        card_h = _orig_h;
    } else {
        // Draw normally
        SCR_CardSlot_DrawBackground();
        SCR_CardSlot_DrawPicture();
        SCR_CardSlot_DrawText();
        SCR_CardSlot_DrawLevel();
        SCR_CardSlot_DrawCountBadge();
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}