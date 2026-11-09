/// @desc OBJ_CardSlot — one card in the collection grid

function SCR_CardSlot_AddToDeck() {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
    
    if (_deckbuilder == noone) return false;
    if (array_length(_deckbuilder.selected_deck) >= collection_GetDeckMaxSize()) return false;
    
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == card_id) {
            
            var _in_deck = SCR_DBD_GetDeckCount(card_id);
            var _available = collection_GetAvailableCopies(global.player_collection[i]);
            if (_available <= 0) {
                var _max = collection_GetMaxDeckCopies(global.player_collection[i]);
                var _owned = variable_struct_exists(global.player_collection[i], "owned")
                    ? global.player_collection[i].owned : 0;
                return false;
            }
            
            // Add to deck
            var _copy = {
                id: card_data.id,
                name: card_data.name,
                type: card_data.type
            };
            array_push(_deckbuilder.selected_deck, _copy);
            SCR_DBD_ShuffleSelectedDeck();
            player_deck_PersistSelectedDeck(_deckbuilder);
            
            // Update badge display (available after this add)
            count = _available - 1;
            image_blend = c_lime;
            
            _deckbuilder.click_processed = true;
            
            // Destroy slot only when no copies left to add
            if (_available - 1 <= 0) {
                instance_destroy();
            }
            
            // REBUILD THE GRID - fills any holes and updates the collection
            SCR_DBD_RebuildGrid();
            
            return true;
        }
    }
    
    return false;
}

function SCR_CardSlot_CheckVisibility() {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);

    if (_deckbuilder == noone) {
        return false;
    }

    var _container_top = _deckbuilder.container_y;
    var _container_bottom = _deckbuilder.container_y + _deckbuilder.container_h;

    if (y + card_h < _container_top || y > _container_bottom) {
        return false;
    }

    return true;
}

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

function SCR_CardSlot_DrawBackground() {
    // Metallic card frame replaces the legacy white card background.
}

function SCR_CardSlot_DrawPicture() {
    card_DrawFramedInRect(x, y, card_w, card_h, card_data, 1);
}

function SCR_CardSlot_DrawText() {
    var _pad = 4;
    var _name = SCR_Hand_TruncateName(card_data.name, card_w - _pad * 2);

    draw_set_color(c_blue);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(x + _pad, y + 3, _name);
    
    var _type_text = card_data.type;
    if (_type_text == "special_monster") {
        _type_text = "spirit";
    }
    
    switch (card_data.type) {
        case "monster":         draw_set_color(c_gray);   break;
        case "special_monster": draw_set_color(c_purple); break;
        case "weapon":          draw_set_color(c_red);    break;
        case "action":          draw_set_color(c_blue);   break;
    }
    draw_set_halign(fa_center);
    draw_text(x + card_w / 2, y + 16, _type_text);
}

function SCR_CardSlot_DrawLevel() {
    var _label = card_GetTierLabel(card_data);
    if (_label == "") return;

    draw_set_color(card_GetTierLabelColor(card_data));
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);
    draw_text(x + 8, y + card_h, _label);
}

function SCR_CardSlot_DrawCountBadge() {

    
    if (count > 0) {
      
        draw_set_color(c_lime);
        draw_circle(x + card_w - 12, y + 12, 10, false);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(x + card_w - 12, y + 12, string(count));
    } else {
    }
}
