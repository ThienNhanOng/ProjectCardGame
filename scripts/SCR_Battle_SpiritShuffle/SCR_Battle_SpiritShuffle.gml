/// @desc Out-of-cards flow — spirit shuffle (discard 3 spirits, refill main deck) or surrender

#macro SPIRIT_SHUFFLE_DISCARD_COST 3
#macro SPIRIT_SURRENDER_DISCARD_COST 2

function battle_SpiritShuffle_Init() {
    spirit_shuffle_active = false;
    spirit_shuffle_phase = "none";
    spirit_shuffle_discard_remaining = 0;
    spirit_shuffle_extra_scroll = 0;
    spirit_shuffle_extra_focus = 0;
}

function battle_SpiritShuffle_IsActive() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) return spirit_shuffle_active;
}

function battle_SpiritShuffle_GetExtraCount() {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return 0;
    with (_deck) return extra_deck_Count;
}

function battle_SpiritShuffle_OnDeckEmpty() {
    if (battle_SpiritShuffle_IsActive()) return;

    var _extra = battle_SpiritShuffle_GetExtraCount();
    if (_extra <= 0) {
        battle_SpiritShuffle_ForceDefeatNoSpirits();
        return;
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        spirit_shuffle_active = true;
        spirit_shuffle_phase = "menu";
        spirit_shuffle_discard_remaining = 0;
    }
}

function battle_SpiritShuffle_ForceDefeatNoSpirits() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) battle_PlayerDefeat();
    }
    battle_ReturnToMapAfterSpiritLoss(0);
}

function battle_SpiritShuffle_CanOfferShuffle() {
    return battle_SpiritShuffle_GetExtraCount() >= SPIRIT_SHUFFLE_DISCARD_COST;
}

function battle_SpiritShuffle_GetMenuButtonRects() {
    var _cx = room_width / 2;
    var _cy = room_height / 2 + 70;
    var _w = 220;
    var _h = 40;
    var _gap = 16;
    var _can_shuffle = battle_SpiritShuffle_CanOfferShuffle();

    if (_can_shuffle) {
        return {
            shuffle: { x1: _cx - _w / 2, y1: _cy - _h - _gap / 2, x2: _cx + _w / 2, y2: _cy - _gap / 2 },
            lose: { x1: _cx - _w / 2, y1: _cy + _gap / 2, x2: _cx + _w / 2, y2: _cy + _h + _gap / 2 }
        };
    }

    return {
        shuffle: undefined,
        lose: { x1: _cx - _w / 2, y1: _cy - _h / 2, x2: _cx + _w / 2, y2: _cy + _h / 2 }
    };
}

function battle_SpiritShuffle_PointInRect(_rect, _mx, _my) {
    if (_rect == undefined) return false;
    return (_mx >= _rect.x1 && _mx <= _rect.x2 && _my >= _rect.y1 && _my <= _rect.y2);
}

function battle_SpiritShuffle_BeginDiscardPick() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        spirit_shuffle_phase = "pick_discard";
        spirit_shuffle_discard_remaining = SPIRIT_SHUFFLE_DISCARD_COST;
        spirit_shuffle_extra_scroll = 0;
        spirit_shuffle_extra_focus = 0;
    }
}

function battle_SpiritShuffle_CompleteShuffle() {
    var _deck = instance_find(OBJ_Deck, 0);
    var _rebuilt = false;
    if (_deck != noone) {
        with (_deck) _rebuilt = deck_RebuildMainDeckFromInitial();
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) battle_SpiritShuffle_Init();
    }

    if (_rebuilt) {
        SCR_Hand_DrawFromDeck();
        return;
    }

    if (battle_SpiritShuffle_GetExtraCount() <= 0) {
        battle_SpiritShuffle_ForceDefeatNoSpirits();
        return;
    }

    if (_bm != noone) {
        with (_bm) {
            spirit_shuffle_active = true;
            spirit_shuffle_phase = "menu";
            spirit_shuffle_discard_remaining = 0;
        }
    }
}

function battle_SpiritShuffle_TryDiscardExtra(_index) {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;
    if (_index < 0 || _index >= _deck.extra_deck_Count) return false;

    with (_deck) deck_RemoveExtraCardAt(_index, true);

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;

    with (_bm) {
        spirit_shuffle_discard_remaining--;
        if (spirit_shuffle_discard_remaining > 0) return true;
    }

    battle_SpiritShuffle_CompleteShuffle();
    return true;
}

function battle_SpiritShuffle_ChooseLose() {
    battle_ReturnToMapAfterSpiritLoss(SPIRIT_SURRENDER_DISCARD_COST);
}

function battle_SpiritShuffle_Step() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;
    if (!_bm.spirit_shuffle_active) return;

    with (_bm) {
        if (spirit_shuffle_phase == "menu") {
            if (!mouse_check_button_pressed(mb_left)) return;

            var _rects = battle_SpiritShuffle_GetMenuButtonRects();
            if (battle_SpiritShuffle_PointInRect(_rects.shuffle, mouse_x, mouse_y)
                && battle_SpiritShuffle_CanOfferShuffle()) {
                battle_SpiritShuffle_BeginDiscardPick();
                battle_SkipFollowUpInputThisFrame();
                return;
            }

            if (battle_SpiritShuffle_PointInRect(_rects.lose, mouse_x, mouse_y)) {
                battle_SpiritShuffle_ChooseLose();
                battle_SkipFollowUpInputThisFrame();
            }
            return;
        }

        if (spirit_shuffle_phase == "pick_discard") {
            var _deck = instance_find(OBJ_Deck, 0);
            if (_deck == noone) {
                battle_SpiritShuffle_ChooseLose();
                return;
            }
            if (_deck.extra_deck_Count <= 0 && spirit_shuffle_discard_remaining > 0) {
                battle_SpiritShuffle_ChooseLose();
                return;
            }

            var _ids = [];
            with (_deck) _ids = deck_ExtraDeckPicker_GetExtraDeckIds();
            var _input = deck_ScrollPicker_ApplyScrollInput(_ids, spirit_shuffle_extra_scroll, spirit_shuffle_extra_focus);
            spirit_shuffle_extra_scroll = _input.scroll;
            spirit_shuffle_extra_focus = _input.focus;

            var _hover_idx = deck_ScrollPicker_PickIndexAt(mouse_x, mouse_y, _ids, spirit_shuffle_extra_scroll);
            if (_hover_idx >= 0) {
                spirit_shuffle_extra_focus = _hover_idx;
                spirit_shuffle_extra_scroll = deck_ScrollPicker_ScrollToFocus(_ids, spirit_shuffle_extra_scroll, _hover_idx);
            }

            if (!mouse_check_button_pressed(mb_left)) return;

            var _idx = -1;
            with (_deck) _idx = deck_ExtraDeckPicker_PickIndexAt(mouse_x, mouse_y);
            if (_idx >= 0) {
                battle_SpiritShuffle_TryDiscardExtra(_idx);
                battle_SkipFollowUpInputThisFrame();
            }
        }
    }
}

function battle_SpiritShuffle_DrawButton(_rect, _label, _enabled = true, _text_color = c_black) {
    if (_rect == undefined) return;

    var _hover = battle_SpiritShuffle_PointInRect(_rect, mouse_x, mouse_y) && _enabled;
    draw_set_alpha(_enabled ? 1 : 0.45);
    draw_set_color(_hover ? c_yellow : (_enabled ? c_white : c_gray));
    draw_rectangle(_rect.x1, _rect.y1, _rect.x2, _rect.y2, false);
    draw_set_color(c_dkgray);
    draw_rectangle(_rect.x1, _rect.y1, _rect.x2, _rect.y2, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_enabled ? _text_color : c_dkgray);
    draw_text((_rect.x1 + _rect.x2) / 2, (_rect.y1 + _rect.y2) / 2, _label);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
}

function battle_SpiritShuffle_Draw() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone || !_bm.spirit_shuffle_active) return;

    draw_set_alpha(0.55);
    draw_set_color(c_black);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);

    with (_bm) {
        if (spirit_shuffle_phase == "menu") {
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_color(c_white);
            draw_text(room_width / 2, room_height / 2 - 90, "Out of cards!");

            var _can_shuffle = battle_SpiritShuffle_CanOfferShuffle();
            if (_can_shuffle) {
                draw_text(room_width / 2, room_height / 2 - 62,
                    "Spirit Shuffle: discard " + string(SPIRIT_SHUFFLE_DISCARD_COST)
                    + " spirits, reshuffle your main deck");
            } else {
                draw_text(room_width / 2, room_height / 2 - 62,
                    "Not enough spirits to shuffle (need " + string(SPIRIT_SHUFFLE_DISCARD_COST) + ")");
            }

            draw_text(room_width / 2, room_height / 2 - 42,
                "Lose: return to map and discard " + string(SPIRIT_SURRENDER_DISCARD_COST) + " spirits at random");

            var _rects = battle_SpiritShuffle_GetMenuButtonRects();
            battle_SpiritShuffle_DrawButton(_rects.shuffle, "Spirit Shuffle", _can_shuffle, c_black);
            battle_SpiritShuffle_DrawButton(_rects.lose, "Lose", true, c_red);
            draw_set_halign(fa_left);
            return;
        }

        if (spirit_shuffle_phase == "pick_discard") {
            draw_set_halign(fa_center);
            draw_set_color(c_yellow);
            draw_text(room_width / 2, 8,
                "Spirit Shuffle — choose " + string(spirit_shuffle_discard_remaining) + " spirit(s) to discard");
            draw_set_halign(fa_left);

            var _deck = instance_find(OBJ_Deck, 0);
            if (_deck == noone) return;

            var _ids = [];
            with (_deck) _ids = deck_ExtraDeckPicker_GetExtraDeckIds();

            deck_ScrollPicker_DrawPanel("Extra Deck", _ids, spirit_shuffle_extra_scroll,
                spirit_shuffle_extra_focus, "No spirits left", "Click card to discard", true);
        }
    }
}

function battle_ReturnToMapAfterSpiritLoss(_discard_count = SPIRIT_SURRENDER_DISCARD_COST) {
    worldmap_InitGlobals();

    battle_DiscardRandomSpirits(_discard_count);
    battle_SyncExtraDeckFromBattleState();

    global.worldmap.active_event_id = -1;
    global.worldmap.victory_pending = false;
    global.worldmap.last_reward_text = "";
    battle_EndSession();

    var _return_room = global.worldmap.return_room;
    if (_return_room == noone) _return_room = Room_Worldmap1;

    room_goto(_return_room);
}

function battle_DiscardRandomSpirits(_count) {
    _count = max(0, floor(_count));
    if (_count <= 0) return;

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return;

    with (_deck) {
        for (var i = 0; i < _count; i++) {
            if (extra_deck_Count <= 0) break;
            var _pick = irandom(extra_deck_Count - 1);
            deck_RemoveExtraCardAt(_pick, true);
        }
    }
}
