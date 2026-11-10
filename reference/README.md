# ProjectCardGame — Reference Documentation

This folder documents the **engine and tools** used to build the game. Actual game content (levels, dialog, art per event) lives in a separate **`content/`** pipeline — see [CONTENT_PIPELINE.md](CONTENT_PIPELINE.md).

## What lives here

| Section | Purpose |
|---------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Full-project overview + master UML |
| [SCRIPT_LAYOUT.md](SCRIPT_LAYOUT.md) | Script folders, naming, shared player/enemy card system, how to add content |
| [uml/](uml/) | Per-system UML diagrams (PlantUML `.puml`) |
| [notes/](notes/) | Short GML-style system summaries (GameMaker note format) |
| [guides/](guides/) | How-to use each system (API, examples, pitfalls) |
| [CONTENT_PIPELINE.md](CONTENT_PIPELINE.md) | How `content/` stores levels, dialog, and event assets |
| [content_FOLDER_EXAMPLE.md](content_FOLDER_EXAMPLE.md) | Copy-paste folder template for a new map event |
| [DEBUG.md](DEBUG.md) | How to re-enable debug overlays and console logs |
| [DEBUG_ARCHIVE.gml](DEBUG_ARCHIVE.gml) | Commented-out debug snippets removed from the game |

## How do I make …?

| To make | Where it's documented |
|---------|-----------------------|
| A player card (monster, weapon, action, spirit) | [../datafiles/README.md](../datafiles/README.md#player-cards-cardsetjson) → *Player cards*, *Examples by type* |
| Card art / the character a card stands on the field as | [../datafiles/README.md](../datafiles/README.md#common-fields) → `sprite`, `field_sprite` |
| An ability (trait) on a card | [../datafiles/README.md](../datafiles/README.md#traits-in-json) → *Traits in JSON* |
| A brand-new trait type (new GML effect) | [../datafiles/README.md](../datafiles/README.md#adding-a-new-trait-type) |
| A keyword (`frontline`, `tag_in`) | [../datafiles/README.md](../datafiles/README.md#keywords) |
| Card costs, tributes, resources | [../datafiles/README.md](../datafiles/README.md#ability--card-cost--tributes) |
| An enemy (stats, moves, stances, summons) | [../datafiles/README.md](../datafiles/README.md#enemies-monstersetjson) |
| An animated enemy sprite | [../datafiles/README.md](../datafiles/README.md#animated-enemies) |
| A battle (enemy wave, how many spots) | [../datafiles/README.md](../datafiles/README.md#battles-battlesets) |
| A battle background (and where the ground must be) | [../datafiles/README.md](../datafiles/README.md#battle-backgrounds-and-where-units-stand) |
| A world map (room, JSON, nodes, linking maps) | [../datafiles/README.md](../datafiles/README.md#world-maps-making-a-new-map) |
| Random side branches on a map | [guides/HOWTO_WorldMap_Events.md](guides/HOWTO_WorldMap_Events.md) |
| Card rewards for clearing a map node | [../datafiles/README.md](../datafiles/README.md#map-marker-card-rewards-world-map) |
| Dialog / a scene before or after a battle | [guides/HOWTO_Dialog.md](guides/HOWTO_Dialog.md) |
| Save slots, accounts, the home screen | [../datafiles/README.md](../datafiles/README.md#home-screen-saves-and-accounts) |
| Debug overlays and logs | [DEBUG.md](DEBUG.md) |

## Systems index

| # | System | Summary note | How-to guide | UML |
|---|--------|--------------|--------------|-----|
| 0 | Content pipeline | [notes/SYSTEM_Content_Pipeline.txt](notes/SYSTEM_Content_Pipeline.txt) | [guides/HOWTO_Content_Pipeline.md](guides/HOWTO_Content_Pipeline.md) | [uml/00_content_pipeline.puml](uml/00_content_pipeline.puml) |
| 1 | Bootstrap & data | [notes/SYSTEM_Bootstrap_Data.txt](notes/SYSTEM_Bootstrap_Data.txt) | [guides/HOWTO_Bootstrap_Data.md](guides/HOWTO_Bootstrap_Data.md) | [uml/01_bootstrap_data.puml](uml/01_bootstrap_data.puml) |
| 2 | Collection & deck builder | [notes/SYSTEM_Collection_DeckBuilder.txt](notes/SYSTEM_Collection_DeckBuilder.txt) | [guides/HOWTO_Collection_DeckBuilder.md](guides/HOWTO_Collection_DeckBuilder.md) | [uml/02_collection_deckbuilder.puml](uml/02_collection_deckbuilder.puml) |
| 3 | Battle manager | [notes/SYSTEM_Battle_Manager.txt](notes/SYSTEM_Battle_Manager.txt) | [guides/HOWTO_Battle_Manager.md](guides/HOWTO_Battle_Manager.md) | [uml/03_battle_manager.puml](uml/03_battle_manager.puml) |
| 4 | Board manager | [notes/SYSTEM_Board_Manager.txt](notes/SYSTEM_Board_Manager.txt) | [guides/HOWTO_Board_Manager.md](guides/HOWTO_Board_Manager.md) | [uml/04_board_manager.puml](uml/04_board_manager.puml) |
| 5 | Hand & deck (battle) | [notes/SYSTEM_Hand_Deck.txt](notes/SYSTEM_Hand_Deck.txt) | [guides/HOWTO_Hand_Deck.md](guides/HOWTO_Hand_Deck.md) | [uml/05_hand_deck.puml](uml/05_hand_deck.puml) |
| 6 | Monster system | [notes/SYSTEM_Monster.txt](notes/SYSTEM_Monster.txt) | [guides/HOWTO_Monster.md](guides/HOWTO_Monster.md) | [uml/06_monster.puml](uml/06_monster.puml) |
| 7 | Traits & effects | [notes/SYSTEM_Traits.txt](notes/SYSTEM_Traits.txt) | [guides/HOWTO_Traits.md](guides/HOWTO_Traits.md) | [uml/07_traits.puml](uml/07_traits.puml) |
| 8 | World map & events | [notes/SYSTEM_WorldMap_Events.txt](notes/SYSTEM_WorldMap_Events.txt) | [guides/HOWTO_WorldMap_Events.md](guides/HOWTO_WorldMap_Events.md) | [uml/08_worldmap_events.puml](uml/08_worldmap_events.puml) |
| 9 | Dialog system | [notes/SYSTEM_Dialog.txt](notes/SYSTEM_Dialog.txt) | [guides/HOWTO_Dialog.md](guides/HOWTO_Dialog.md) | [uml/09_dialog.puml](uml/09_dialog.puml) |

## Master UML

See [uml/full_project.puml](uml/full_project.puml) or the embedded diagram in [ARCHITECTURE.md](ARCHITECTURE.md).

Preview `.puml` files with the [PlantUML extension](https://marketplace.visualstudio.com/items?itemName=jebbs.plantuml) or [plantuml.com](https://www.plantuml.com/plantuml).

## Object parent-child tree

```
OBJ_EventMarker
├── OBJ_Map1_Marker01 … OBJ_Map1_Marker05
└── OBJ_Map2_Marker01 … OBJ_Map2_Marker08

(All other objects: no inheritance parent)
```

## Room flow (player journey)

```
Room_home → Room_collection (new game: build a deck) → Room_Worldmap1 → Room_battle → Room_Worldmap1 → … → Room_Worldmap2 → …
Esc on a map or in the deck builder → Room_home (Continue goes back)
```

## Related docs outside this folder

- `datafiles/README.md` — how to make cards, enemies, battles, battle backgrounds, world maps, traits; saves
- `notes/Map1Markers guide/` — legacy marker setup guide
- `notes/Dialog System guide/` — legacy dialog guide
