/// @desc Draw container and UI

// Draw container background
draw_set_color(c_black);
draw_set_alpha(0.3);
draw_rectangle(container_x, container_y, container_x + container_w, container_y + container_h, false);
draw_set_alpha(1);

// Draw container border
draw_set_color(c_white);
draw_rectangle(container_x, container_y, container_x + container_w, container_y + container_h, true);

// Draw container label (left side above container)
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(container_x, container_y - 20, "Card Collection");

// Draw page info (right side above container)
var _total_pages = ceil(array_length(card_DB.cards) / cards_per_page);
draw_set_color(c_white);
draw_set_halign(fa_right);
draw_text(container_x + container_w - 10, container_y - 20, "Page " + string(current_page + 1) + "/" + string(_total_pages));
draw_set_halign(fa_left);

// Draw deck count (bottom left)
draw_set_color(c_white);
draw_text(20, room_height - 85, "Deck: " + string(array_length(selected_deck)) + "/40");

// Ready button
if (array_length(selected_deck) >= 8) {
    draw_set_color(c_green);
} else {
    draw_set_color(c_red);
}
draw_rectangle(room_width - 150, room_height - 100, room_width - 20, room_height - 60, false);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_text(room_width - 85, room_height - 88, "READY");
draw_set_halign(fa_left);

// ===== DRAW DECK LIST ON RIGHT SIDE =====
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(room_width - 180, 60, "=== YOUR DECK ===");

// Draw each card in the deck
for (var i = 0; i < array_length(selected_deck); i++) {
    var _y = 80 + (i * 18);
    
    // Stop if off screen
    if (_y > room_height - 100) {
        draw_text(room_width - 180, _y, "... and more");
        break;
    }
    
    draw_text(room_width - 180, _y, 
              string(i + 1) + ". " + selected_deck[i].name);
}

// Draw deck count summary
draw_set_color(c_yellow);
draw_text(room_width - 180, room_height - 610, 
          "Total: " + string(array_length(selected_deck)) + " / 40 cards");

// Draw minimum requirement warning
if (array_length(selected_deck) < 8) {
    draw_set_color(c_red);
    draw_text(room_width - 180, room_height - 50, 
              "Need at least 8 cards to start!");
}