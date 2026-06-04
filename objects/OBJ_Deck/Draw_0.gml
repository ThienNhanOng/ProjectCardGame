// draw the deck pile sprite with a visual stack buffer
for (var i = 0; i < deck_Count; i++) {
    draw_sprite(SPR_Cardback, 0, deck_X + (i * 0.4), deck_Y - (i * 0.4));
}

// draw how many cards are left
draw_set_color(c_white);
draw_text(deck_X, deck_Y + deck_Height + 5, "Cards: " + string(deck_Count));