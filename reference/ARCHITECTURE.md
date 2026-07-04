# Full Project Architecture

## Master UML — all systems

```mermaid
flowchart TB
    subgraph CONTENT["content/ (game authoring)"]
        C_MAP[maps / events / dialog / art]
        C_JSON[cards / enemies / battlesets JSON]
    end

    subgraph BOOT["1. Bootstrap & Data"]
        GC[OBJ_GameController]
        LC[LoadCollection]
        LM[LoadMonsters]
        PC[SCR_PlayerCollection]
        GC --> LC --> card_DB[(card_DB)]
        GC --> LM --> monster_DB[(monster_DB)]
        GC --> PC --> player_col[(global.player_collection)]
    end

    subgraph DECK["2. Collection & Deck Builder"]
        DBC[OBJ_DeckBuilder]
        CS[OBJ_CardSlot]
        DBC --> CS
        DBC -->|READY| battle_deck[(battle_deck_source)]
    end

    subgraph MAP["8. World Map & Events"]
        WMC[OBJ_WorldMapController]
        PM[OBJ_PlayerMarker]
        EM[OBJ_EventMarker]
        M1[OBJ_Map1_Marker01..05]
        EM --> M1
        WMC --> worldmap[(global.worldmap)]
        PM -->|E interact| EM
        EM -->|launch| battle_cfg[(battle_runtime_config)]
    end

    subgraph DIALOG["9. Dialog"]
        DC[OBJ_DialogController]
        DS[SCR_Dialog_System]
        DB[SCR_Dialog_Builder]
        EM -->|pre/post| DS
        DC --> DS
        DS --> DB
    end

    subgraph BATTLE["3–7. Battle Room"]
        BM[OBJ_BattleManager]
        BRD[OBJ_BoardManager]
        HD[OBJ_Hand]
        DK[OBJ_Deck]
        MM[OBJ_MonsterManager]

        BM --> BRD
        BM --> HD
        HD --> DK
        BM --> MM
        BM --> TR[7. Traits SCR_Trait_*]
    end

    C_JSON --> BOOT
    C_MAP --> MAP
    C_MAP --> DIALOG

    BOOT --> DECK
    DECK -->|room_goto| MAP
    MAP -->|worldmap_LaunchEventBattle| BATTLE
    BATTLE -->|victory| MAP
    MAP -->|Collection button| DECK
```

## Object hierarchy (inheritance)

```mermaid
classDiagram
    class OBJ_EventMarker {
        eventmarker_init()
        eventmarker_trigger()
        marker_dialog_pre
        marker_battle
    }
    class OBJ_Map1_Marker01
    class OBJ_Map1_Marker02
    class OBJ_Map1_Marker03
    class OBJ_Map1_Marker04
    class OBJ_Map1_Marker05
    class OBJ_Map2_Marker01

    OBJ_EventMarker <|-- OBJ_Map1_Marker01
    OBJ_EventMarker <|-- OBJ_Map1_Marker02
    OBJ_EventMarker <|-- OBJ_Map1_Marker03
    OBJ_EventMarker <|-- OBJ_Map1_Marker04
    OBJ_EventMarker <|-- OBJ_Map1_Marker05
    OBJ_EventMarker <|-- OBJ_Map2_Marker01
```

## Room & instance flow

```mermaid
sequenceDiagram
    participant RC as Room_collection
    participant RW as Room_Worldmap1
    participant RB as Room_battle

    RC->>RC: OBJ_GameController loads DBs
    RC->>RC: OBJ_DeckBuilder READY saves deck
    RC->>RW: room_goto map
    RW->>RW: worldmap_InitRoom sync markers
    RW->>RW: Player E at marker
    opt pre-dialog once
        RW->>RW: dialog_Start pre
    end
    RW->>RB: worldmap_LaunchEventBattle
    RB->>RB: battle_BeginSession
    RB->>RB: turns / traits / monsters
    RB->>RW: worldmap_ReturnToMapAfterVictory
    RW->>RW: spawn above marker + rewards
    opt post-dialog once
        RW->>RW: dialog_TryRunPendingPost
    end
```

## Global state map

| Global | Owner system | Purpose |
|--------|--------------|---------|
| `card_DB` | Bootstrap | All card definitions |
| `monster_DB` | Bootstrap | All enemy definitions |
| `global.player_collection` | Collection | Owned cards |
| `global.battle_deck_source` | Deck builder | Main deck IDs for battle |
| `global.battle_extra_deck_source` | Deck builder | Spirit extra deck |
| `global.worldmap` | World map | Cleared events, rewards, spawn |
| `global.battle_runtime_config` | World map → Battle | Active battle wave config |
| `global.dialog` | Dialog | Active dialog runtime |
| `global.battleset_cache` | Bootstrap | Parsed battleset JSON cache |

## Battle room creation order

Critical order in `Room_battle`:

1. `OBJ_GameController`
2. `OBJ_Deck`
3. `OBJ_Hand`
4. `OBJ_BoardManager`
5. `OBJ_BattleManager`
6. `OBJ_MonsterManager`

## Engine vs content summary

Everything under `scripts/`, `objects/`, and shared `sprites/` placeholders = **tools**.

Per-level dialog, marker configs, map art, battlesets, reward tables = **content** (target: `content/` folder).

See [CONTENT_PIPELINE.md](CONTENT_PIPELINE.md) and per-system guides in [guides/](guides/).
