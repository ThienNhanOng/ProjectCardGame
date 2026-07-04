// DEBUG ARCHIVE — all show_debug_message calls removed from the live game (June 2026 cleanup)
// Re-enable via SCR_Debug.gml macros, or uncomment lines and paste back into source files.

// =============================================================================
// ON-SCREEN DEBUG — use SCR_Debug macros (preferred)
// =============================================================================

// World map HUD (was SCR_WorldMap_Controller_DrawHUD):
// draw_text(12, _gh - 72, "Map: " + global.worldmap.map_id);
// draw_text(12, _gh - 56, "Progress: " + string(array_length(global.worldmap.cleared))
//     + " / " + string(array_length(global.worldmap.event_flow)));
// draw_text(12, _gh - 40, "WASD move | E interact at active markers");

// Battle status overlay (was SCR_Monster_DrawDebugCounter):
// draw_text(10, 10, "Queue: " + string(monster_GetQueueCount())
//     + " | Slots: " + string(active_slot_count)
//     + " | Field: " + string(_living)
//     + " | DB: " + string(_db_count));
// draw_text(10, 26, "Battle: " + battle_name);
//   Queue  = spawn queue remaining
//   Slots  = enemy board slots this wave
//   Field  = living enemies on board NOW
//   DB     = monster_DB.enemies count (database size, not battlefield)
// draw_text(10, 42, "Victory!");

// Hand count (was OBJ_Hand Draw):
// draw_text(10, 10, "Hand Count: " + string(hand_Count));

// Mouse coordinates (was DebugOBJ_cordinates Draw):
// draw_text(23, 21, string(mouse_x) + " " + string(mouse_y));

// =============================================================================
// CONSOLE LOG — set DEBUG_LOG_ENABLED true in SCR_Debug.gml, or use debug_Log()
// =============================================================================

// --- World map ---
// show_debug_message("World map config not found: " + _filename);
// show_debug_message("World map loaded: " + global.worldmap.map_id + " | Events: " + string(array_length(global.worldmap.event_flow)));
// show_debug_message("World map event cleared: " + string(_id));
// show_debug_message("World map synced " + string(array_length(_markers)) + " markers");
// show_debug_message("Launching " + _label + " -> " + _battle_id);
// show_debug_message("Event " + string(_event_id) + " is locked");

// --- Dialog ---
// show_debug_message("dialog: could not load background sprite (" + string(_ref) + ")");
// show_debug_message("dialog_Start: expected a script function");

// --- Battle / board ---
// show_debug_message("MonsterManager ready | Battle: " + battle_name);
// show_debug_message("=== Player turn " + string(turn_number) + " | Drew 1 card ===");
// show_debug_message("Placed " + _card.name + " in " + _slot.type + " slot " + string(_slot.index));
// show_debug_message("Dragging: " + drag_card.name);
// show_debug_message("Column attack " + string(_parts.monster_strike) + "+" + string(_parts.weapon_strike));
// show_debug_message("[EnemyLog] " + _line);

// --- Traits ---
// show_debug_message("Trait attack " + string(_ctx.amount) + " -> enemy slot " + string(_ctx.target_enemy_slot));
// show_debug_message("Drew " + string(_drawn) + " card(s) from deck");
// show_debug_message("Trait not implemented yet: " + string(_trait.type));

// --- Collection / deck builder ---
// show_debug_message("DeckBuilder Created");
// show_debug_message("Added " + card_data.name + " | Remaining: " + string(_available - 1));
// show_debug_message("Need at least 8 cards to start!");
// show_debug_message("Loaded " + string(deck_Count) + " cards into battle deck (fresh copy, shuffled)");

// --- Data load ---
// show_debug_message("Collection not found: " + _filename);
// show_debug_message("Loaded: " + _collection.collection + " | Cards: " + string(array_length(_new_cards)));
// show_debug_message("Total cards in DB: " + string(array_length(card_DB.cards)));
// show_debug_message("Total enemies in DB: " + string(array_length(global.monster_DB.enemies)));
// show_debug_message("Loaded battle: " + string(_config.battle));

// --- Camera (Room_battle creation code) ---
// show_debug_message("Camera X: " + string(camera_get_view_x(_cam)));

// --- Deck debug dump ---
// show_debug_message("=== DECK CONTENTS ===");
// show_debug_message("Slot " + string(i) + ": ID " + string(_card_id) + " - " + _card_name);

// Full per-file list was generated during cleanup (~200 calls across scripts/objects/rooms).
// Search this project git history or backup for additional lines if needed.
