// ===== TEST COLLECTION MANAGER =====
// This file manages the player's card collection for testing

// Global collection variable
global.player_collection = [];

// Setup test collection - add cards you want to test
function SetupTestCollection() {
    // Clear existing collection
    global.player_collection = [];
    
    // Add each card ONLY ONCE with total owned count
    // Format: AddCardToCollection(card_id, amount)
    AddCardToCollection(1, 5);   // Card ID 1 - Goblin I - own 6 copies
    AddCardToCollection(2, 10);   // Card ID 2 - Goblin Warrior - own 2 copies
    AddCardToCollection(3, 3);   // Card ID 3 - Goblin Tank - own 1 copy
    AddCardToCollection(4, 3);
	AddCardToCollection(5, 5);   // Card ID 5 - Goblin Strike (action) - own 3 copies
    AddCardToCollection(7, 5);
	AddCardToCollection(8, 5);
	AddCardToCollection(9, 5);   // Card ID 8 - Goblin Sword (weapon) - own 5 copies
    AddCardToCollection(10, 2);  // Card ID 10 - Spirit Card - own 2 copies

    // Trait demo sets (ids 101-109 monsters, 201-209 actions, 301+ mix)
    AddCardToCollection(101, 3);
    AddCardToCollection(102, 3);
    AddCardToCollection(103, 3);
    AddCardToCollection(104, 3);
    AddCardToCollection(105, 3);
    AddCardToCollection(106, 3);
    AddCardToCollection(107, 3);
    AddCardToCollection(108, 3);
    AddCardToCollection(109, 3);
    AddCardToCollection(201, 3);
    AddCardToCollection(202, 3);
    AddCardToCollection(203, 3);
    AddCardToCollection(204, 3);
    AddCardToCollection(205, 3);
    AddCardToCollection(206, 3);
    AddCardToCollection(207, 3);
    AddCardToCollection(208, 3);
    AddCardToCollection(209, 3);
    AddCardToCollection(301, 2);
    AddCardToCollection(302, 2);
    AddCardToCollection(303, 2);
    AddCardToCollection(311, 2);
    AddCardToCollection(312, 2);
    AddCardToCollection(313, 2);
    
    show_debug_message("=== Test Collection Ready ===");
    show_debug_message("Total card types: " + string(array_length(global.player_collection)));
    
    // Debug: Show collection contents
    for (var i = 0; i < array_length(global.player_collection); i++) {
        show_debug_message("  " + global.player_collection[i].name + " | ID:" + string(global.player_collection[i].id) + " | Owned:" + string(global.player_collection[i].owned));
    }
}

// Add a card to collection (prevents duplicates)
function AddCardToCollection(_card_id, _amount) {
    // FIRST: Check if card already exists in collection
    for (var c = 0; c < array_length(global.player_collection); c++) {
        if (global.player_collection[c].id == _card_id) {
            // Add to existing entry
            global.player_collection[c].owned += _amount;
            show_debug_message("Added " + _amount + " more to existing: " + global.player_collection[c].name);
            return true;
        }
    }
    
    // SECOND: Find card in master database and add new
    for (var i = 0; i < array_length(card_DB.cards); i++) {
        if (card_DB.cards[i].id == _card_id) {
            // Copy the ENTIRE card as-is (all properties preserved)
            var _new_card = card_DB.cards[i];
            // Just add the owned property
            _new_card.owned = _amount;
            array_push(global.player_collection, _new_card);
            show_debug_message("Added NEW: " + _new_card.name + " x" + string(_amount));
            return true;
        }
    }
    
    show_debug_message("ERROR: Card ID " + string(_card_id) + " not found in database!");
    return false;
}

// Get the player's collection
function GetPlayerCollection() {
    return global.player_collection;
}

// Get owned count for a specific card
function GetCardOwned(_card_id) {
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == _card_id) {
            return global.player_collection[i].owned;
        }
    }
    return 0;
}

// Decrease owned count (when adding to deck)
function DecreaseCardOwned(_card_id) {
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == _card_id && global.player_collection[i].owned > 0) {
            global.player_collection[i].owned--;
            show_debug_message("Decreased " + global.player_collection[i].name + " - Now owned: " + string(global.player_collection[i].owned));
            return true;
        }
    }
    return false;
}

// Increase owned count (when removing from deck)
function IncreaseCardOwned(_card_id) {
    for (var i = 0; i < array_length(global.player_collection); i++) {
        if (global.player_collection[i].id == _card_id) {
            global.player_collection[i].owned++;
            show_debug_message("Increased " + global.player_collection[i].name + " - Now owned: " + string(global.player_collection[i].owned));
            return true;
        }
    }
    return false;
}

// Clear entire collection (for testing)
function ClearCollection() {
    global.player_collection = [];
    show_debug_message("Collection cleared!");
}

// Debug: Print current collection
function DebugPrintCollection() {
    show_debug_message("=== CURRENT COLLECTION ===");
    for (var i = 0; i < array_length(global.player_collection); i++) {
        show_debug_message(string(i) + ". " + global.player_collection[i].name + 
                          " (ID:" + string(global.player_collection[i].id) + 
                          ") Owned: " + string(global.player_collection[i].owned));
    }
    show_debug_message("Total card types: " + string(array_length(global.player_collection)));
}