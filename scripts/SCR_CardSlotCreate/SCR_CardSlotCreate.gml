function SCR_CardSlotCreate(_card_id, _card_data, _count, _card_w, _card_h) {
    card_id   = _card_id;
    card_data = _card_data;
    count     = _count;
    card_w    = _card_w;
    card_h    = _card_h;
    image_blend = c_white;
}

// In OBJ_CardSlot Create Event or wherever you set card dimensions
card_w = 90;  // Was 73, now wider to fit "King Beast"
card_h = 101;