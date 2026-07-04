# How to Use — Dialog System

## Purpose

Overlay dialog on world map: portraits, typewriter lines, colored text, optional full-screen background images.

## Main scripts

- `SCR_Dialog_System` — `dialog_Start`, `dialog_Step`, `dialog_DrawGui`
- `SCR_Dialog_Builder` — entry builders (`dialog_LineKey`, `dialog_Left`, …)
- `SCR_Dialog_Text` — colored text parse, text-script format
- Content example: `SCR_DialogExample_map1marker`

## Main objects

- `OBJ_DialogController` — Draw GUI calls `dialog_DrawGui()`

## Responsibilities

- Advance through script entry array
- Draw order: full-screen bg (if set) → tint → portraits → text box
- Block map movement while active
- Pre/post integration via `eventmarker_set_dialog_*`

## Dependencies

- `SCR_WorldMap_Controller` calls `dialog_Step()` each frame
- Marker stashes `pending_dialog_post` before battle

## Public API

### Builder (return from script function)

```gml
function dialog_MyEvent_Intro() {
    return [
        dialog_NameHero("Hero"),
        dialog_NameGuide("Guide"),
        dialog_Left(SPR_Dialog_Player, "hero", true),
        dialog_Right(SPR_Dialog_Testcharacter, "guide", true),
        dialog_LineKey("hero", "Ready?"),
        dialog_LineKey("guide", "Stay sharp."),
        dialog_Background(SPR_BG_GrassTest, true),  // pops on next lines
        dialog_LineKey("hero", "Look — grasslands!"),
        dialog_HideBackground(),
        dialog_ClearChars()
    ];
}
```

### Runtime

```gml
dialog_Start(dialog_MyEvent_Intro, optional_callback);
dialog_IsActive();
dialog_ForceClose();
```

### Marker integration

```gml
eventmarker_set_dialog_pre(dialog_MyEvent_Intro);
eventmarker_set_dialog_pre_once(true);  // no replay after event cleared
eventmarker_set_dialog_post(dialog_MyEvent_Outro);
```

### Text script format (alternative)

```
namehero Hero
(left) SPR_Dialog_Player hero
hero: Hello world
(bg) SPR_BG_GrassTest
hero: Background changed
```

Use `dialog_FromText(string)` to parse.

## Initialization order

```
Map load → dialog_Init()
OBJ_DialogController in room (Draw GUI event)
SCR_WorldMapController Step → dialog_Step()
```

## Runtime flow

```
dialog_Start → process entries (name/portrait/bg/line) → draw GUI → advance on click/space → callback
```

## Example usage

Background only when told (not at dialog start):
```gml
dialog_LineKey("hero", "Still on the map view."),
dialog_Background(SPR_BG_GrassTest, true),
dialog_LineKey("hero", "Now the scene changes."),
```

## Common pitfalls

- `SPR_Field` is the **battle board** — use `SPR_BG_GrassTest` or map art for dialog
- Background must be placed **before** the line where it should appear
- Draw uses **Draw GUI** (eventType 8, eventNum 64) — must stay above map layers
- `dialog_Background(sprite, false)` or `dialog_HideBackground()` returns to map-only tint

## Future expansion

- Branching choices entry kind
- Load lines from `content/.../dialog_pre.txt`

## Parent / child

`OBJ_DialogController` — no parent. Dialog **content** is script functions, not child objects.

Portrait sprites: `SPR_Dialog_Player`, `SPR_Dialog_Testcharacter` under `sprites/characters/`.
