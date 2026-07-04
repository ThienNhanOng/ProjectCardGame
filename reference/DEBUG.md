# Debug System

All runtime debug output has been **removed from the game**. Use `SCR_Debug.gml` to turn features back on.

## Quick enable

In `scripts/SCR_Debug/SCR_Debug.gml`, set macros to `true`:

| Macro | What it shows |
|-------|----------------|
| `DEBUG_LOG_ENABLED` | All `debug_Log()` console messages |
| `DEBUG_DRAW_WORLDMAP_INFO` | Map id, progress, WASD hint (bottom-left) |
| `DEBUG_DRAW_BATTLE_STATUS` | Battle overlay top-left (see below) |
| `DEBUG_DRAW_MOUSE_XY` | Mouse x/y (needs `DebugOBJ_cordinates` in room, or call from Draw) |
| `DEBUG_DRAW_HAND_COUNT` | Hand count top-left |
| `DEBUG_DRAW_ENEMY_HITBOXES` | Enemy slot hover hitboxes |

## Battle overlay explained

When `DEBUG_DRAW_BATTLE_STATUS` is on, top-left shows:

```
Queue: 2 | Slots: 3 | Field: 1 | DB: 24
Battle: battle01
```

| Label | Meaning |
|-------|---------|
| **Queue** | Enemies still waiting in the spawn queue |
| **Slots** | Enemy board slots allocated this wave |
| **Field** | Enemies **alive on the board right now** |
| **DB** | Total enemy definitions loaded in `monster_DB` (not board state) |
| **Battle: battle01** | Current battleset battle id |

**Field** = who is on the field fighting. **DB** = how many enemy types exist in the JSON database.

## Console log archive

`reference/DEBUG_ARCHIVE.gml` lists every `show_debug_message` that was removed from the project (commented out). Copy any line back into source, or use `debug_Log("your message")` with `DEBUG_LOG_ENABLED true`.

## Removed from rooms

- `DebugOBJ_cordinates` removed from `Room_battle` (was mouse x/y overlay). Re-add the instance to use `DEBUG_DRAW_MOUSE_XY`, or call `debug_DrawMouseCoordinates()` from any Draw event.

## Performance note

With all macros `false`, debug draw functions compile to empty stubs — no per-frame string work or console spam.
