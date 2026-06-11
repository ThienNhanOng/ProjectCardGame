function SCR_CardSlot_VisualFeedback(_success) {
    if (_success) {
        image_blend = c_lime;
 
        show_debug_message("Added " + card_data.name);
    } else {
        image_blend = c_red;
       
        show_debug_message("Deck is full!");
    }
}