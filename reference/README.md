# ProjectCardGame — Reference Documentation

This folder documents the **engine and tools** used to build the game. Actual game content (levels, dialog, art per event) lives in a separate **`content/`** pipeline — see [CONTENT_PIPELINE.md](CONTENT_PIPELINE.md).

## What lives here

| Section | Purpose |
|---------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Full-project overview + master UML |
| [uml/](uml/) | Per-system UML diagrams (Mermaid) |
| [notes/](notes/) | Short GML-style system summaries (GameMaker note format) |
| [guides/](guides/) | How-to use each system (API, examples, pitfalls) |
| [CONTENT_PIPELINE.md](CONTENT_PIPELINE.md) | How `content/` stores levels, dialog, and event assets |
| [content_FOLDER_EXAMPLE.md](content_FOLDER_EXAMPLE.md) | Copy-paste folder template for a new map event |
| [DEBUG.md](DEBUG.md) | How to re-enable debug overlays and console logs |
| [DEBUG_ARCHIVE.gml](DEBUG_ARCHIVE.gml) | Commented-out debug snippets removed from the game |

## Systems index

| # | System | Summary note | How-to guide | UML |
|---|--------|--------------|--------------|-----|
| 0 | Content pipeline | [notes/SYSTEM_Content_Pipeline.txt](notes/SYSTEM_Content_Pipeline.txt) | [guides/HOWTO_Content_Pipeline.md](guides/HOWTO_Content_Pipeline.md) | [uml/00_content_pipeline.mmd](uml/00_content_pipeline.mmd) |
| 1 | Bootstrap & data | [notes/SYSTEM_Bootstrap_Data.txt](notes/SYSTEM_Bootstrap_Data.txt) | [guides/HOWTO_Bootstrap_Data.md](guides/HOWTO_Bootstrap_Data.md) | [uml/01_bootstrap_data.mmd](uml/01_bootstrap_data.mmd) |
| 2 | Collection & deck builder | [notes/SYSTEM_Collection_DeckBuilder.txt](notes/SYSTEM_Collection_DeckBuilder.txt) | [guides/HOWTO_Collection_DeckBuilder.md](guides/HOWTO_Collection_DeckBuilder.md) | [uml/02_collection_deckbuilder.mmd](uml/02_collection_deckbuilder.mmd) |
| 3 | Battle manager | [notes/SYSTEM_Battle_Manager.txt](notes/SYSTEM_Battle_Manager.txt) | [guides/HOWTO_Battle_Manager.md](guides/HOWTO_Battle_Manager.md) | [uml/03_battle_manager.mmd](uml/03_battle_manager.mmd) |
| 4 | Board manager | [notes/SYSTEM_Board_Manager.txt](notes/SYSTEM_Board_Manager.txt) | [guides/HOWTO_Board_Manager.md](guides/HOWTO_Board_Manager.md) | [uml/04_board_manager.mmd](uml/04_board_manager.mmd) |
| 5 | Hand & deck (battle) | [notes/SYSTEM_Hand_Deck.txt](notes/SYSTEM_Hand_Deck.txt) | [guides/HOWTO_Hand_Deck.md](guides/HOWTO_Hand_Deck.md) | [uml/05_hand_deck.mmd](uml/05_hand_deck.mmd) |
| 6 | Monster system | [notes/SYSTEM_Monster.txt](notes/SYSTEM_Monster.txt) | [guides/HOWTO_Monster.md](guides/HOWTO_Monster.md) | [uml/06_monster.mmd](uml/06_monster.mmd) |
| 7 | Traits & effects | [notes/SYSTEM_Traits.txt](notes/SYSTEM_Traits.txt) | [guides/HOWTO_Traits.md](guides/HOWTO_Traits.md) | [uml/07_traits.mmd](uml/07_traits.mmd) |
| 8 | World map & events | [notes/SYSTEM_WorldMap_Events.txt](notes/SYSTEM_WorldMap_Events.txt) | [guides/HOWTO_WorldMap_Events.md](guides/HOWTO_WorldMap_Events.md) | [uml/08_worldmap_events.mmd](uml/08_worldmap_events.mmd) |
| 9 | Dialog system | [notes/SYSTEM_Dialog.txt](notes/SYSTEM_Dialog.txt) | [guides/HOWTO_Dialog.md](guides/HOWTO_Dialog.md) | [uml/09_dialog.mmd](uml/09_dialog.mmd) |

## Master UML

See [uml/full_project.mmd](uml/full_project.mmd) or the embedded diagram in [ARCHITECTURE.md](ARCHITECTURE.md).

## Object parent-child tree

```
OBJ_EventMarker
├── OBJ_Map1_Marker01 … OBJ_Map1_Marker05
└── OBJ_Map2_Marker01

(All other objects: no inheritance parent)
```

## Room flow (player journey)

```
Room_collection → Room_Worldmap1 → Room_battle → Room_Worldmap1 → …
```

## Related docs outside this folder

- `datafiles/README.md` — JSON field reference for cards, enemies, battles, traits
- `notes/Map1Markers guide/` — legacy marker setup guide
- `notes/Dialog System guide/` — legacy dialog guide
