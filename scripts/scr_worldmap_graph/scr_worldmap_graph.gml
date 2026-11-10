/// @desc World map node graph — your story path plus random side branches, and node-to-node travel.
///
/// Nodes (ids):
///   0           the start point (where the player is placed in the room)
///   1 .. n      your hand-placed story markers, in story order (event_flow) — unchanged behaviour
///   1001 ...    random side events branching off a story node
///
/// Links: start - story 1 - story 2 - ... (a story node opens once the one before it is cleared),
/// plus the side branches. Each side node stores "parent" and "children" (pointers by id),
/// so a branch is a small tree hanging off one story node:
///
///   story --> side --> side          (chain)
///   side <-- story --> side          (fork: one on each side of the path)
///   story --> side                   (single)
///
/// After you win a story battle for the first time, a side branch may appear there (map JSON "side_events").
/// A branch stays until every node in it is done; it disappears once you walk off it after that.
/// Several branches (one per story node) can be on the map at once.
///
/// Travel: WASD / arrow keys slide to the linked node in that direction, or click a glowing node.
/// Arriving never starts anything: E / Enter starts (or replays) the node you stand on.
/// With the mouse, clicking a node that would start something asks "Are you sure you want to go here?" Yes / No.
///
/// "side_events" settings in the map JSON (all optional):
///   chance           0..1 chance of a branch after each first story win (default 0.5)
///   shape_weights    { "single": 1, "fork": 1, "chain": 1 } how often each shape appears (0 = never)
///   treasure_chance  0..1 chance a single / fork node is a treasure instead of a battle (default 0.3)
///   chain_treasure_chance  0..1 chance a chain is battle -> treasure instead of battle -> battle (default 0.5)
///   places           names for treasure scenes ("Hero has explored the <place>.")
///   battle_names     names shown on side battle nodes (picked at random, no repeats while unused ones remain)
///   treasure_names   names shown on treasure nodes
///   treasure_rewards [{ "id": 8, "chance": 100, "once": true }, ...]
///   battle_rewards   same format — one card per won single / fork side battle (empty = no card)
///   chain_battle_rewards   battle -> battle chain: each of the two battles drops one card from this list
///                    (battle -> treasure chain: the battle drops nothing, only the treasure gives a card)

#macro WORLDMAP_NODE_START 0
#macro WORLDMAP_SIDE_ID_BASE 1000
#macro WORLDMAP_NODE_TRAVEL_SPEED 420
#macro WORLDMAP_NODE_TRAVEL_MIN_TIME 0.35
#macro WORLDMAP_NODE_CLICK_RADIUS 30
#macro WORLDMAP_SIDE_OFFSET 115
#macro WORLDMAP_CONFIRM_W 360
#macro WORLDMAP_CONFIRM_H 130
#macro WORLDMAP_CONFIRM_BTN_W 100
#macro WORLDMAP_CONFIRM_BTN_H 34

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

/// Read the "side_events" block of a map JSON (undefined = no random side events)
function worldmap_SideReadSettings(_data) {
    if (!variable_struct_exists(_data, "side_events") || !is_struct(_data.side_events)) return undefined;

    var _src = _data.side_events;
    return {
        chance: clamp(real(variable_struct_exists(_src, "chance") ? _src.chance : 0.5), 0, 1),
        treasure_chance: clamp(real(variable_struct_exists(_src, "treasure_chance") ? _src.treasure_chance : 0.3), 0, 1),
        chain_treasure_chance: clamp(real(variable_struct_exists(_src, "chain_treasure_chance") ? _src.chain_treasure_chance : 0.5), 0, 1),
        shape_weights: variable_struct_exists(_src, "shape_weights") ? _src.shape_weights : { single: 1, fork: 1, chain: 1 },
        chain_battle_rewards: variable_struct_exists(_src, "chain_battle_rewards") ? _src.chain_battle_rewards : [],
        places: variable_struct_exists(_src, "places") ? _src.places : ["valley", "forest clearing", "old ruins", "riverbank", "hillside cave"],
        battle_names: variable_struct_exists(_src, "battle_names") ? _src.battle_names : ["Side battle"],
        treasure_names: variable_struct_exists(_src, "treasure_names") ? _src.treasure_names : ["Treasure"],
        treasure_rewards: variable_struct_exists(_src, "treasure_rewards") ? _src.treasure_rewards : [],
        battle_rewards: variable_struct_exists(_src, "battle_rewards") ? _src.battle_rewards : []
    };
}

function worldmap_IsSideId(_id) {
    return _id > WORLDMAP_SIDE_ID_BASE;
}

function worldmap_IsStoryId(_id) {
    return _id >= 1 && _id <= WORLDMAP_SIDE_ID_BASE;
}

// ---------------------------------------------------------------------------
// Room setup (called from worldmap_InitRoom after the story markers are synced)
// ---------------------------------------------------------------------------

function worldmap_NodeSetupRoom() {
    worldmap_InitGlobals();
    var _wm = global.worldmap;
    _wm.node_confirm = -1;

    // new map: forget the old position and branch
    if (_wm.node_map_key != _wm.config_file) {
        _wm.node_map_key = _wm.config_file;
        _wm.node_pos = WORLDMAP_NODE_START;
        _wm.side_branches = [];
        _wm.side_next_id = WORLDMAP_SIDE_ID_BASE + 1;
        _wm.side_pending = -1;
        _wm.node_start = undefined;
    }

    // the start point is where the player is placed in the room
    if (_wm.node_start == undefined) {
        var _player = instance_find(OBJ_PlayerMarker, 0);
        _wm.node_start = (_player != noone) ? { x: _player.x, y: _player.y } : { x: 60, y: 320 };
    }

    // side branches survive the trip to a battle and back
    for (var b = 0; b < array_length(_wm.side_branches); b++) {
        var _nodes = _wm.side_branches[b].nodes;
        for (var i = 0; i < array_length(_nodes); i++) {
            worldmap_SideRegisterEvent(_nodes[i]);
            worldmap_SideSpawnMarker(_nodes[i]);
        }
    }
    worldmap_SideRemoveFinishedBranches();

    // a branch rolled after a battle is built now that the story markers exist
    if (_wm.side_pending > 0) {
        var _anchor = _wm.side_pending;
        _wm.side_pending = -1;
        worldmap_SideCreateBranch(_anchor);
    }
}

/// Coming back from a battle / entering through a marker: stand on that node
function worldmap_NodePlaceAtEvent(_event_id) {
    if (_event_id <= 0) return;
    global.worldmap.node_pos = _event_id;
}

// ---------------------------------------------------------------------------
// Positions and links
// ---------------------------------------------------------------------------

function worldmap_StoryIds() {
    return global.worldmap.event_flow;
}

/// Centre of a node in room coordinates (undefined if the node does not exist)
function worldmap_NodeGetPos(_id) {
    if (_id == WORLDMAP_NODE_START) return global.worldmap.node_start;

    if (worldmap_IsSideId(_id)) {
        var _side = worldmap_SideGetNode(_id);
        return (_side == undefined) ? undefined : { x: _side.x, y: _side.y };
    }

    var _marker = worldmap_GetEventMarkerById(_id);
    if (_marker == noone) return undefined;
    return { x: _marker.x + _marker.sprite_width * 0.5, y: _marker.y + _marker.sprite_height * 0.5 };
}

/// Where the player stands on a node (player sprite origin is at its feet)
function worldmap_NodeGetStandPos(_id) {
    var _pos = worldmap_NodeGetPos(_id);
    if (_pos == undefined) return undefined;
    if (_id == WORLDMAP_NODE_START) return _pos;
    return { x: _pos.x, y: _pos.y + 6 };
}

/// Nodes linked to _id that the player may travel to right now
function worldmap_NodeGetLinks(_id) {
    var _links = [];
    var _story = worldmap_StoryIds();
    var _count = array_length(_story);

    if (_id == WORLDMAP_NODE_START) {
        if (_count > 0) array_push(_links, _story[0]);
        return _links;
    }

    if (worldmap_IsSideId(_id)) {
        var _side = worldmap_SideGetNode(_id);
        if (_side == undefined) return _links;
        array_push(_links, _side.parent);
        if (worldmap_IsEventCleared(_id)) {
            for (var c = 0; c < array_length(_side.children); c++) array_push(_links, _side.children[c]);
        }
        return _links;
    }

    // story node: previous story node (or the start), the next one once this is cleared, and its side branch
    var _index = -1;
    for (var i = 0; i < _count; i++) if (_story[i] == _id) _index = i;
    if (_index < 0) return _links;

    array_push(_links, (_index > 0) ? _story[_index - 1] : WORLDMAP_NODE_START);
    if (_index + 1 < _count && worldmap_IsEventCleared(_id)) array_push(_links, _story[_index + 1]);

    if (worldmap_IsEventCleared(_id)) {
        var _branches = global.worldmap.side_branches;
        for (var b = 0; b < array_length(_branches); b++) {
            if (_branches[b].anchor != _id) continue;
            for (var r = 0; r < array_length(_branches[b].roots); r++) array_push(_links, _branches[b].roots[r]);
        }
    }
    return _links;
}

function worldmap_NodeCanTravel(_to) {
    return array_contains(worldmap_NodeGetLinks(global.worldmap.node_pos), _to);
}

/// Linked node under a point, or -1 (with _include_current, also the node you stand on)
function worldmap_NodeAtPoint(_px, _py, _include_current = false) {
    var _candidates = worldmap_NodeGetLinks(global.worldmap.node_pos);
    if (_include_current) array_push(_candidates, global.worldmap.node_pos);

    var _best = -1;
    var _best_dist = WORLDMAP_NODE_CLICK_RADIUS;
    for (var i = 0; i < array_length(_candidates); i++) {
        var _pos = worldmap_NodeGetPos(_candidates[i]);
        if (_pos == undefined) continue;
        var _dist = point_distance(_px, _py, _pos.x, _pos.y);
        if (_dist <= _best_dist) {
            _best = _candidates[i];
            _best_dist = _dist;
        }
    }
    return _best;
}

/// Linked node that best matches a WASD direction, or -1
function worldmap_NodeInDirection(_dx, _dy) {
    var _from = worldmap_NodeGetPos(global.worldmap.node_pos);
    var _links = worldmap_NodeGetLinks(global.worldmap.node_pos);
    var _len = point_distance(0, 0, _dx, _dy);
    if (_from == undefined || _len <= 0) return -1;

    var _best = -1;
    var _best_score = 0.3;   // must be roughly in that direction
    for (var i = 0; i < array_length(_links); i++) {
        var _pos = worldmap_NodeGetPos(_links[i]);
        if (_pos == undefined) continue;
        var _vx = _pos.x - _from.x;
        var _vy = _pos.y - _from.y;
        var _vlen = point_distance(0, 0, _vx, _vy);
        if (_vlen <= 0) continue;
        var _score = (_vx * _dx + _vy * _dy) / (_vlen * _len);
        if (_score > _best_score) {
            _best_score = _score;
            _best = _links[i];
        }
    }
    return _best;
}

// ---------------------------------------------------------------------------
// Player travel (runs on OBJ_PlayerMarker)
// ---------------------------------------------------------------------------

function worldmap_NodePlayerStep(_inst) {
    if (_inst == noone) return;

    with (_inst) {
        if (!variable_instance_exists(id, "node_ready") || !node_ready) {
            node_ready = true;
            travel_active = false;
            travel_node = -1;
            travel_autostart = false;
            depth = -20;
            var _stand = worldmap_NodeGetStandPos(global.worldmap.node_pos);
            if (_stand == undefined) {
                global.worldmap.node_pos = WORLDMAP_NODE_START;
                _stand = worldmap_NodeGetStandPos(WORLDMAP_NODE_START);
            }
            x = _stand.x;
            y = _stand.y;
        }

        if (travel_active) {
            var _dt = delta_time / 1000000;
            if (_dt <= 0) _dt = 1 / max(1, game_get_speed(gamespeed_fps));
            travel_t = min(1, travel_t + _dt / travel_time);

            // smooth start and stop, with a small hop along the way
            var _e = travel_t * travel_t * (3 - 2 * travel_t);
            x = lerp(travel_x1, travel_x2, _e);
            y = lerp(travel_y1, travel_y2, _e) - sin(travel_t * pi) * 10;

            if (travel_t >= 1) {
                travel_active = false;
                x = travel_x2;
                y = travel_y2;
                worldmap_NodeArrive(travel_node, travel_autostart);
                travel_autostart = false;
            }
            return;
        }
    }

    if (dialog_IsActive()) return;

    // "Are you sure?" box open: it takes all input
    if (global.worldmap.node_confirm >= 0) {
        worldmap_NodeConfirmStep(_inst);
        return;
    }

    // Esc: the home screen (save / load / exit)
    if (keyboard_check_pressed(vk_escape)) {
        save_OpenHomeMenu();
        return;
    }

    // WASD / arrow keys
    var _dx = (keyboard_check_pressed(ord("D")) || keyboard_check_pressed(vk_right))
        - (keyboard_check_pressed(ord("A")) || keyboard_check_pressed(vk_left));
    var _dy = (keyboard_check_pressed(ord("S")) || keyboard_check_pressed(vk_down))
        - (keyboard_check_pressed(ord("W")) || keyboard_check_pressed(vk_up));
    if (_dx != 0 || _dy != 0) {
        var _target = worldmap_NodeInDirection(_dx, _dy);
        if (_target >= 0) {
            worldmap_NodeTravelTo(_inst, _target);
            return;
        }
    }

    // mouse: clicking a node that would start something asks first; done nodes are just travelled to
    if (mouse_check_button_pressed(mb_left) && !worldmap_IsMouseOverCollectionButton() && !worldmap_IsMouseOverMenuButton()) {
        var _clicked = worldmap_NodeAtPoint(mouse_x, mouse_y, true);
        if (_clicked < 0) return;
        if (worldmap_NodeClickWouldStart(_clicked)) {
            global.worldmap.node_confirm = _clicked;
        } else if (_clicked != global.worldmap.node_pos) {
            worldmap_NodeTravelTo(_inst, _clicked);
        }
    }
}

/// Clicking this node would start an event (an unfinished node, or replaying the story node you stand on)
function worldmap_NodeClickWouldStart(_node_id) {
    if (_node_id == WORLDMAP_NODE_START) return false;
    if (!worldmap_CanInteractEvent(_node_id)) return false;
    if (!worldmap_IsEventCleared(_node_id)) return true;
    return _node_id == global.worldmap.node_pos && worldmap_IsStoryId(_node_id);
}

// ---------------------------------------------------------------------------
// "Are you sure you want to go here?" (mouse only)
// ---------------------------------------------------------------------------

function worldmap_NodeConfirmGetRects() {
    var _cx = display_get_gui_width() * 0.5;
    var _cy = display_get_gui_height() * 0.5;
    var _by = _cy + WORLDMAP_CONFIRM_H * 0.5 - WORLDMAP_CONFIRM_BTN_H - 16;
    return {
        box: { x1: _cx - WORLDMAP_CONFIRM_W * 0.5, y1: _cy - WORLDMAP_CONFIRM_H * 0.5, x2: _cx + WORLDMAP_CONFIRM_W * 0.5, y2: _cy + WORLDMAP_CONFIRM_H * 0.5 },
        yes: { x1: _cx - 20 - WORLDMAP_CONFIRM_BTN_W, y1: _by, x2: _cx - 20, y2: _by + WORLDMAP_CONFIRM_BTN_H },
        no: { x1: _cx + 20, y1: _by, x2: _cx + 20 + WORLDMAP_CONFIRM_BTN_W, y2: _by + WORLDMAP_CONFIRM_BTN_H }
    };
}

function worldmap_NodeConfirmStep(_inst) {
    var _r = worldmap_NodeConfirmGetRects();
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _yes = keyboard_check_pressed(ord("Y"));
    var _no = keyboard_check_pressed(ord("N")) || keyboard_check_pressed(vk_escape);
    if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(_mx, _my, _r.yes.x1, _r.yes.y1, _r.yes.x2, _r.yes.y2)) _yes = true;
        else if (point_in_rectangle(_mx, _my, _r.no.x1, _r.no.y1, _r.no.x2, _r.no.y2)) _no = true;
    }
    if (_yes) worldmap_NodeConfirmAnswer(_inst, true);
    else if (_no) worldmap_NodeConfirmAnswer(_inst, false);
}

/// Yes: go there and start it (or start the node you stand on). No: nothing happens.
function worldmap_NodeConfirmAnswer(_inst, _yes) {
    var _node_id = global.worldmap.node_confirm;
    global.worldmap.node_confirm = -1;
    if (!_yes || _node_id < 0) return false;

    if (_node_id == global.worldmap.node_pos) return worldmap_NodeStart(_node_id, worldmap_IsStoryId(_node_id));
    if (!worldmap_NodeTravelTo(_inst, _node_id)) return false;
    _inst.travel_autostart = true;
    return true;
}

function worldmap_NodeGetLabel(_node_id) {
    if (worldmap_IsSideId(_node_id)) {
        var _side = worldmap_SideGetNode(_node_id);
        return (_side == undefined) ? "?" : _side.label;
    }
    var _def = worldmap_GetEventDef(_node_id);
    return (_def != undefined && _def.label != "") ? _def.label : "Event " + string(_node_id);
}

/// Draw GUI
function worldmap_NodeDrawConfirm() {
    var _node_id = global.worldmap.node_confirm;
    if (_node_id < 0) return;

    var _r = worldmap_NodeConfirmGetRects();
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    draw_set_alpha(0.45);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(0.95);
    draw_set_color(make_color_rgb(30, 34, 48));
    draw_rectangle(_r.box.x1, _r.box.y1, _r.box.x2, _r.box.y2, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(_r.box.x1, _r.box.y1, _r.box.x2, _r.box.y2, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var _cx = (_r.box.x1 + _r.box.x2) * 0.5;
    var _question = (_node_id == global.worldmap.node_pos && worldmap_IsEventCleared(_node_id))
        ? "Are you sure you want to replay this?" : "Are you sure you want to go here?";
    draw_text(_cx, _r.box.y1 + 16, _question);
    draw_set_color(c_yellow);
    draw_text(_cx, _r.box.y1 + 40, worldmap_NodeGetLabel(_node_id));

    var _buttons = [["Yes", _r.yes, make_color_rgb(60, 140, 70)], ["No", _r.no, make_color_rgb(150, 60, 60)]];
    draw_set_valign(fa_middle);
    for (var i = 0; i < 2; i++) {
        var _b = _buttons[i][1];
        var _hover = point_in_rectangle(_mx, _my, _b.x1, _b.y1, _b.x2, _b.y2);
        draw_set_color(_hover ? merge_color(_buttons[i][2], c_white, 0.3) : _buttons[i][2]);
        draw_rectangle(_b.x1, _b.y1, _b.x2, _b.y2, false);
        draw_set_color(c_white);
        draw_rectangle(_b.x1, _b.y1, _b.x2, _b.y2, true);
        draw_text((_b.x1 + _b.x2) * 0.5, (_b.y1 + _b.y2) * 0.5, _buttons[i][0]);
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function worldmap_NodeTravelTo(_inst, _node_id) {
    if (!worldmap_NodeCanTravel(_node_id)) return false;

    var _pos = worldmap_NodeGetStandPos(_node_id);
    if (_pos == undefined) return false;

    with (_inst) {
        travel_active = true;
        travel_node = _node_id;
        travel_t = 0;
        travel_x1 = x;
        travel_y1 = y;
        travel_x2 = _pos.x;
        travel_y2 = _pos.y;
        travel_time = max(WORLDMAP_NODE_TRAVEL_MIN_TIME, point_distance(x, y, _pos.x, _pos.y) / WORLDMAP_NODE_TRAVEL_SPEED);
        if (_pos.x != x) image_xscale = sign(_pos.x - x);
    }
    return true;
}

/// _start: the player confirmed this node with the mouse (Yes) - start it on arrival
function worldmap_NodeArrive(_node_id, _start = false) {
    var _wm = global.worldmap;
    _wm.node_pos = _node_id;

    worldmap_SideRemoveFinishedBranches();   // a fully done branch disappears once you walk off it

    // arriving never starts anything by itself: E / Enter does, or a confirmed mouse click
    if (_start) worldmap_NodeStart(_node_id, false);
}

/// Start (or with _replay, replay) the node you stand on
function worldmap_NodeStart(_node_id, _replay) {
    if (_node_id == WORLDMAP_NODE_START) return false;
    if (!worldmap_CanInteractEvent(_node_id)) return false;
    if (worldmap_IsEventCleared(_node_id) && !_replay) return false;

    if (worldmap_IsSideId(_node_id)) {
        var _side = worldmap_SideGetNode(_node_id);
        if (_side.type == "treasure") {
            worldmap_SideStartTreasure(_side);
            return true;
        }
    }

    var _marker = worldmap_GetEventMarkerById(_node_id);
    if (_marker == noone) return false;
    with (_marker) eventmarker_trigger();
    return true;
}

/// E / Enter on the node you stand on: start it, or replay a cleared story battle
function worldmap_NodeTryInteract(_inst) {
    if (dialog_IsActive() || global.worldmap.node_confirm >= 0) return false;
    if (variable_instance_exists(_inst, "travel_active") && _inst.travel_active) return false;
    var _pos = global.worldmap.node_pos;
    return worldmap_NodeStart(_pos, worldmap_IsStoryId(_pos));
}

// ---------------------------------------------------------------------------
// Side branches
// ---------------------------------------------------------------------------

function worldmap_SideGetNode(_id) {
    var _branch = worldmap_SideGetBranchOf(_id);
    if (_branch == undefined) return undefined;
    for (var i = 0; i < array_length(_branch.nodes); i++) {
        if (_branch.nodes[i].id == _id) return _branch.nodes[i];
    }
    return undefined;
}

/// The branch a side node belongs to (undefined if none)
function worldmap_SideGetBranchOf(_id) {
    var _branches = global.worldmap.side_branches;
    for (var b = 0; b < array_length(_branches); b++) {
        var _nodes = _branches[b].nodes;
        for (var i = 0; i < array_length(_nodes); i++) {
            if (_nodes[i].id == _id) return _branches[b];
        }
    }
    return undefined;
}

function worldmap_SideBranchIsFinished(_branch) {
    for (var i = 0; i < array_length(_branch.nodes); i++) {
        if (!worldmap_IsEventCleared(_branch.nodes[i].id)) return false;
    }
    return true;
}

/// Remove every branch whose nodes are all done, unless the player is still standing on it
function worldmap_SideRemoveFinishedBranches() {
    var _branches = global.worldmap.side_branches;
    var _here = global.worldmap.node_pos;
    for (var b = array_length(_branches) - 1; b >= 0; b--) {
        var _branch = _branches[b];
        if (!worldmap_SideBranchIsFinished(_branch)) continue;
        if (worldmap_SideGetBranchOf(_here) == _branch) continue;
        worldmap_SideRemoveBranch(_branch);
    }
}

/// Called when an event is cleared. A first story win may open a side branch there.
function worldmap_NodeOnEventCleared(_event_id, _first_clear) {
    if (!_first_clear || !worldmap_IsStoryId(_event_id)) return;

    var _settings = global.worldmap.side_events;
    if (_settings == undefined) return;
    if (random(1) >= _settings.chance) return;

    // this runs in the battle room: the branch is built when the map room loads (worldmap_NodeSetupRoom)
    global.worldmap.side_pending = _event_id;
}

/// Build 1-2 random side nodes off a story node: single, chain (story -> a -> b) or fork (one each side)
function worldmap_SideCreateBranch(_anchor_id) {
    var _anchor = worldmap_NodeGetPos(_anchor_id);
    if (_anchor == undefined) return;

    // direction along the story path here, and the perpendicular "sideways" direction
    var _dir = worldmap_StoryDirectionAt(_anchor_id);
    var _px = -_dir.y;
    var _py = _dir.x;
    var _side_sign = worldmap_SidePickSide(_anchor, _px, _py);

    var _settings = global.worldmap.side_events;
    var _shape = worldmap_SidePickShape(_settings.shape_weights);
    var _branch = { anchor: _anchor_id, roots: [], nodes: [], shape: _shape };
    array_push(global.worldmap.side_branches, _branch);

    var _base = global.worldmap.side_next_id;
    global.worldmap.side_next_id += 2;
    var _story_battle = "";
    var _def = worldmap_GetEventDef(_anchor_id);
    if (_def != undefined) _story_battle = _def.battle;

    switch (_shape) {
        case "single":   // left OR right: battle or treasure
            var _s1 = worldmap_SideAddNode(_branch, _base, _anchor_id,
                _anchor.x + _px * _side_sign * WORLDMAP_SIDE_OFFSET, _anchor.y + _py * _side_sign * WORLDMAP_SIDE_OFFSET, _story_battle,
                worldmap_SideRollType(), _settings.battle_rewards);
            array_push(_branch.roots, _s1.id);
            break;

        case "chain":    // twice in a row: battle -> battle (each drops from chain_battle_rewards) or battle -> treasure (only the treasure drops)
            var _to_treasure = random(1) < _settings.chain_treasure_chance;
            _branch.shape = _to_treasure ? "chain_battle_treasure" : "chain_battle_battle";
            var _battle_drops = _to_treasure ? [] : _settings.chain_battle_rewards;
            var _c1 = worldmap_SideAddNode(_branch, _base, _anchor_id,
                _anchor.x + _px * _side_sign * WORLDMAP_SIDE_OFFSET, _anchor.y + _py * _side_sign * WORLDMAP_SIDE_OFFSET, _story_battle,
                "battle", _battle_drops);
            var _c2 = worldmap_SideAddNode(_branch, _base + 1, _c1.id,
                _c1.x + _dir.x * 70 + _px * _side_sign * 70, _c1.y + _dir.y * 70 + _py * _side_sign * 70, _story_battle,
                _to_treasure ? "treasure" : "battle", _battle_drops);
            array_push(_c1.children, _c2.id);
            array_push(_branch.roots, _c1.id);
            break;

        case "fork":     // left AND right: each battle or treasure
            var _f1 = worldmap_SideAddNode(_branch, _base, _anchor_id,
                _anchor.x + _px * WORLDMAP_SIDE_OFFSET, _anchor.y + _py * WORLDMAP_SIDE_OFFSET, _story_battle,
                worldmap_SideRollType(), _settings.battle_rewards);
            var _f2 = worldmap_SideAddNode(_branch, _base + 1, _anchor_id,
                _anchor.x - _px * WORLDMAP_SIDE_OFFSET, _anchor.y - _py * WORLDMAP_SIDE_OFFSET, _story_battle,
                worldmap_SideRollType(), _settings.battle_rewards);
            array_push(_branch.roots, _f1.id);
            array_push(_branch.roots, _f2.id);
            break;
    }

    for (var i = 0; i < array_length(_branch.nodes); i++) {
        worldmap_SideRegisterEvent(_branch.nodes[i]);
        worldmap_SideSpawnMarker(_branch.nodes[i]);
    }
}

/// _type "battle" / "treasure"; _battle_rewards = the card list this node's battle drops from ([] = no card)
function worldmap_SideAddNode(_branch, _id, _parent, _x, _y, _story_battle, _type, _battle_rewards) {
    var _settings = global.worldmap.side_events;
    var _bounds = worldmap_GetMovementBounds();

    var _node = {
        id: _id,
        parent: _parent,
        children: [],
        type: _type,
        x: round(clamp(_x, _bounds.x1 + 30, _bounds.x2 - 30)),
        y: round(clamp(_y, _bounds.y1 + 40, _bounds.y2 - 20)),
        battle: (_type == "battle") ? worldmap_SidePickBattle(_story_battle) : "",
        label: worldmap_SidePickName((_type == "battle") ? _settings.battle_names : _settings.treasure_names, (_type == "battle") ? "Side battle" : "Treasure"),
        treasure_card: 0,
        rewards: (_type == "battle") ? eventmarker_CopyRewardEntries(_battle_rewards) : []
    };
    array_push(_branch.nodes, _node);
    return _node;
}

/// Single / fork node: treasure with treasure_chance, otherwise a battle
function worldmap_SideRollType() {
    return (random(1) < global.worldmap.side_events.treasure_chance) ? "treasure" : "battle";
}

/// "single" / "fork" / "chain" by shape_weights
function worldmap_SidePickShape(_weights) {
    var _names = ["single", "fork", "chain"];
    var _total = 0;
    var _w = [0, 0, 0];
    for (var i = 0; i < 3; i++) {
        _w[i] = (is_struct(_weights) && variable_struct_exists(_weights, _names[i])) ? max(0, real(_weights[$ _names[i]])) : 1;
        _total += _w[i];
    }
    if (_total <= 0) return "single";
    var _roll = random(_total);
    for (var j = 0; j < 3; j++) {
        if (_roll < _w[j]) return _names[j];
        _roll -= _w[j];
    }
    return "chain";
}

/// A name from the list, preferring ones not already shown on the map
function worldmap_SidePickName(_names, _fallback) {
    if (!is_array(_names) || array_length(_names) <= 0) return _fallback;

    var _unused = [];
    for (var i = 0; i < array_length(_names); i++) {
        var _name = string(_names[i]);
        var _taken = false;
        with (OBJ_EventMarker) if (marker_label == _name) _taken = true;
        var _branches = global.worldmap.side_branches;
        for (var b = 0; b < array_length(_branches) && !_taken; b++) {
            for (var n = 0; n < array_length(_branches[b].nodes); n++) if (_branches[b].nodes[n].label == _name) _taken = true;
        }
        if (!_taken) array_push(_unused, _name);
    }
    var _pool = (array_length(_unused) > 0) ? _unused : _names;
    return string(_pool[irandom(array_length(_pool) - 1)]);
}

/// Unit direction of the story path at a story node (towards the next node, else from the previous one)
function worldmap_StoryDirectionAt(_id) {
    var _story = worldmap_StoryIds();
    var _index = -1;
    for (var i = 0; i < array_length(_story); i++) if (_story[i] == _id) _index = i;

    var _here = worldmap_NodeGetPos(_id);
    var _other = undefined;
    var _flip = 1;
    if (_index >= 0 && _index + 1 < array_length(_story)) _other = worldmap_NodeGetPos(_story[_index + 1]);
    if (_other == undefined) {
        _other = (_index > 0) ? worldmap_NodeGetPos(_story[_index - 1]) : global.worldmap.node_start;
        _flip = -1;
    }
    var _dx = (_other.x - _here.x) * _flip;
    var _dy = (_other.y - _here.y) * _flip;
    var _len = point_distance(0, 0, _dx, _dy);
    if (_len <= 0) return { x: 1, y: 0 };
    return { x: _dx / _len, y: _dy / _len };
}

/// Which side of the path (+1 / -1) has more room: inside the map and away from other markers
function worldmap_SidePickSide(_anchor, _px, _py) {
    var _bounds = worldmap_GetMovementBounds();
    var _best_sign = 1;
    var _best_score = -infinity;
    var _signs = [1, -1];
    for (var s = 0; s < 2; s++) {
        var _tx = _anchor.x + _px * _signs[s] * WORLDMAP_SIDE_OFFSET;
        var _ty = _anchor.y + _py * _signs[s] * WORLDMAP_SIDE_OFFSET;
        var _score = 0;
        if (_tx < _bounds.x1 + 30 || _tx > _bounds.x2 - 30 || _ty < _bounds.y1 + 40 || _ty > _bounds.y2 - 20) _score -= 1000;
        var _nearest = infinity;
        with (OBJ_EventMarker) _nearest = min(_nearest, point_distance(_tx, _ty, x + sprite_width * 0.5, y + sprite_height * 0.5));
        _score += min(_nearest, 300);
        if (_score > _best_score) {
            _best_score = _score;
            _best_sign = _signs[s];
        }
    }
    return _best_sign;
}

/// A battle near the story battle's difficulty (battleset order: easiest first)
function worldmap_SidePickBattle(_story_battle) {
    var _ids = [];
    var _data = data_ReadJsonFile(global.worldmap.battleset_file);
    if (_data != undefined && variable_struct_exists(_data, "battles") && is_array(_data.battles)) {
        for (var i = 0; i < array_length(_data.battles); i++) {
            if (variable_struct_exists(_data.battles[i], "battle")) array_push(_ids, string(_data.battles[i].battle));
        }
    }
    if (array_length(_ids) <= 0) return _story_battle;

    var _index = 0;
    for (var j = 0; j < array_length(_ids); j++) if (_ids[j] == _story_battle) _index = j;
    return _ids[clamp(_index + irandom_range(-1, 1), 0, array_length(_ids) - 1)];
}

/// Event definition for a side node, so the normal battle / reward code can run it
function worldmap_SideRegisterEvent(_node) {
    var _rewards = (_node.type == "battle" && variable_struct_exists(_node, "rewards")) ? _node.rewards : [];

    global.worldmap.events[$ worldmap_GetEventKey(_node.id)] = {
        id: _node.id,
        label: _node.label,
        battle: _node.battle,
        battleset_file: global.worldmap.battleset_file,
        replay_pool: (_node.type == "battle") ? [_node.battle] : [],
        reward_gift_count: (array_length(_rewards) > 0) ? 1 : 0,
        reward_randomize: true,
        reward_entries: _rewards
    };
}

function worldmap_SideSpawnMarker(_node) {
    if (worldmap_GetEventMarkerById(_node.id) != noone) return;

    var _marker = instance_create_depth(_node.x, _node.y, -10, OBJ_EventMarker);
    with (_marker) {
        event_id = _node.id;
        marker_label = _node.label;
        marker_event_type = EVENT_TYPE.BATTLE;
        node_type = _node.type;
        // marker sprites have a top-left origin: centre them on the node
        x = _node.x - sprite_get_width(Map_Marker_inactive) * 0.5;
        y = _node.y - sprite_get_height(Map_Marker_inactive) * 0.5;
        eventmarker_refresh_visual();
    }
}

/// A side branch disappears: markers, events and its cleared flags
function worldmap_SideRemoveBranch(_branch) {
    var _wm = global.worldmap;

    for (var i = 0; i < array_length(_branch.nodes); i++) {
        var _id = _branch.nodes[i].id;
        var _marker = worldmap_GetEventMarkerById(_id);
        if (_marker != noone) instance_destroy(_marker);
        var _key = worldmap_GetEventKey(_id);
        if (variable_struct_exists(_wm.events, _key)) variable_struct_remove(_wm.events, _key);
        for (var c = array_length(_wm.cleared) - 1; c >= 0; c--) {
            if (_wm.cleared[c] == _id) array_delete(_wm.cleared, c, 1);
        }
    }
    for (var b = array_length(_wm.side_branches) - 1; b >= 0; b--) {
        if (_wm.side_branches[b] == _branch) array_delete(_wm.side_branches, b, 1);
    }
}

/// Side node state: available until done, then cleared
function worldmap_SideGetEventState(_id) {
    if (worldmap_SideGetNode(_id) == undefined) return WORLDMAP_EVENT_STATE.LOCKED;
    return worldmap_IsEventCleared(_id) ? WORLDMAP_EVENT_STATE.CLEARED : WORLDMAP_EVENT_STATE.AVAILABLE;
}

// ---------------------------------------------------------------------------
// Treasure: a short scene, then a card
// ---------------------------------------------------------------------------

function worldmap_SideStartTreasure(_node) {
    var _settings = global.worldmap.side_events;
    if (_node.treasure_card <= 0) _node.treasure_card = worldmap_SidePickTreasureCard();

    var _places = _settings.places;
    var _place = (is_array(_places) && array_length(_places) > 0) ? string(_places[irandom(array_length(_places) - 1)]) : "area";
    var _card_name = (_node.treasure_card > 0) ? deck_GetCardName(_node.treasure_card) : "nothing";

    var _scene = method({ place: _place, card_name: _card_name }, function() {
        return [
            dialog_LeftName("Hero"),
            dialog_Left(SPR_Dialog_Player),
            dialog_HideRight(),
            dialog_LeftLine("Hero has explored the " + place + "."),
            dialog_LeftLine("What's this?!?!"),
            dialog_LeftLine("Found a card - " + card_name)
        ];
    });
    var _done = method({ node_id: _node.id, card_id: _node.treasure_card }, function() {
        worldmap_SideFinishTreasure(node_id, card_id);
    });

    dialog_Start(_scene, _done);
}

function worldmap_SideFinishTreasure(_node_id, _card_id) {
    if (worldmap_IsEventCleared(_node_id)) return;

    if (_card_id > 0 && collection_GrantBattleReward(_card_id, 1, "")) {
        worldmap_MarkRewardObtained({ id: _card_id, chance: 100, collection: "", once: worldmap_SideTreasureIsOnce(_card_id) });
    }
    worldmap_MarkEventCleared(_node_id);
}

/// A card from the map's treasure pool (falls back to any non-spirit card)
function worldmap_SidePickTreasureCard() {
    var _pool = worldmap_FilterAvailableRewardEntries(global.worldmap.side_events.treasure_rewards);
    if (array_length(_pool) > 0) return worldmap_PickWeightedRewardEntry(_pool).id;

    var _ids = [];
    for (var i = 0; i < array_length(card_DB.cards); i++) {
        var _card = card_DB.cards[i];
        if (_card.id > 0 && !card_IsSpiritType(_card)) array_push(_ids, _card.id);
    }
    if (array_length(_ids) <= 0) return 0;
    return _ids[irandom(array_length(_ids) - 1)];
}

function worldmap_SideTreasureIsOnce(_card_id) {
    var _entries = global.worldmap.side_events.treasure_rewards;
    for (var i = 0; i < array_length(_entries); i++) {
        var _entry = worldmap_NormalizeRewardEntry(_entries[i]);
        if (_entry.id == _card_id) return _entry.once;
    }
    return false;
}

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

/// Paths between nodes (OBJ_WorldMapController Draw — under the markers and the player)
function worldmap_NodeDrawPaths() {
    var _story = worldmap_StoryIds();
    var _here = global.worldmap.node_pos;
    var _links = worldmap_NodeGetLinks(_here);

    // story path: start - 1 - 2 - ...
    var _prev = WORLDMAP_NODE_START;
    for (var i = 0; i < array_length(_story); i++) {
        var _id = _story[i];
        var _style = "locked";
        if (worldmap_IsEventCleared(_id)) _style = "done";
        else if (_prev == WORLDMAP_NODE_START || worldmap_IsEventCleared(_prev)) _style = "open";
        worldmap_NodeDrawLink(_prev, _id, _style);
        _prev = _id;
    }

    // side branch
    var _branches = global.worldmap.side_branches;
    for (var b = 0; b < array_length(_branches); b++) {
        for (var n = 0; n < array_length(_branches[b].nodes); n++) {
            var _side = _branches[b].nodes[n];
            worldmap_NodeDrawLink(_side.parent, _side.id, worldmap_IsEventCleared(_side.id) ? "done" : "side");
        }
    }

    // glow under the nodes you can travel to; ring on the one under the mouse
    var _hover = worldmap_NodeAtPoint(mouse_x, mouse_y, false);
    for (var l = 0; l < array_length(_links); l++) {
        var _pos = worldmap_NodeGetPos(_links[l]);
        if (_pos == undefined || _links[l] == WORLDMAP_NODE_START) continue;
        draw_set_alpha(0.25 + 0.15 * sin(current_time / 180));
        draw_set_color(worldmap_IsSideId(_links[l]) ? c_orange : c_yellow);
        draw_circle(_pos.x, _pos.y, 28, false);
        draw_set_alpha(1);
        if (_links[l] == _hover) {
            draw_set_color(c_white);
            draw_circle(_pos.x, _pos.y, 30, true);
            draw_circle(_pos.x, _pos.y, 31, true);
        }
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// style: "done" (solid white), "open" (pulsing yellow), "side" (orange), "locked" (faint)
function worldmap_NodeDrawLink(_from, _to, _style) {
    var _a = worldmap_NodeGetPos(_from);
    var _b = worldmap_NodeGetPos(_to);
    if (_a == undefined || _b == undefined) return;

    var _color = c_ltgray;
    var _width = 2;
    var _dashed = true;
    var _alpha = 0.7;
    switch (_style) {
        case "done": _color = c_white; _width = 4; _dashed = false; _alpha = 1; break;
        case "open": _color = c_yellow; _width = 3; _alpha = 0.75 + 0.25 * sin(current_time / 180); break;
        case "side": _color = c_orange; _width = 3; _alpha = 0.75 + 0.25 * sin(current_time / 180); break;
    }
    // dark shadow first so paths read on any map art
    draw_set_alpha(0.55 * _alpha);
    worldmap_NodeDrawLine(_a.x, _a.y, _b.x, _b.y, c_black, _width + 3, _dashed);
    draw_set_alpha(_alpha);
    worldmap_NodeDrawLine(_a.x, _a.y, _b.x, _b.y, _color, _width, _dashed);
    draw_set_alpha(1);
}

function worldmap_NodeDrawLine(_x1, _y1, _x2, _y2, _color, _width, _dashed) {
    draw_set_color(_color);
    if (!_dashed) {
        draw_line_width(_x1, _y1, _x2, _y2, _width);
        return;
    }
    var _len = point_distance(_x1, _y1, _x2, _y2);
    var _dash = 10;
    for (var d = 0; d < _len; d += _dash * 2) {
        var _t1 = d / _len;
        var _t2 = min(1, (d + _dash) / _len);
        draw_line_width(lerp(_x1, _x2, _t1), lerp(_y1, _y2, _t1), lerp(_x1, _x2, _t2), lerp(_y1, _y2, _t2), _width);
    }
}

/// HUD hint (Draw GUI)
function worldmap_NodeDrawHint() {
    if (global.worldmap.node_confirm >= 0) return;
    var _pos = global.worldmap.node_pos;
    var _text = "WASD / click a glowing node to travel";
    if (_pos != WORLDMAP_NODE_START && !worldmap_IsEventCleared(_pos)) _text = "Press E / Enter to start  -  " + _text;
    else if (worldmap_IsStoryId(_pos)) _text += "  -  E / Enter to replay this battle";

    var _x = display_get_gui_width() * 0.5;
    var _y = display_get_gui_height() - 32;
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_black);
    draw_text(_x + 1, _y + 1, _text);
    draw_set_color(c_white);
    draw_text(_x, _y, _text);
    draw_set_halign(fa_left);
}
