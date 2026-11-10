/// @desc Save system — accounts, 4 save slots (slot 1 = autosave, 2-4 manual), quick save / load.
///
/// Each account gets its own local save folder the first time it is used (the player's local save database):
///   <save area>/saves/accounts.json            which account was used last
///   <save area>/saves/<account>/profile.json   written when the account is first used
///   <save area>/saves/<account>/slot1.json     autosave (written whenever a world map is entered)
///   <save area>/saves/<account>/slot2.json ... slot4.json   manual saves
/// The save area is GameMaker's own folder for this game (%LOCALAPPDATA%\ProjectCardGame on Windows),
/// so a fresh download starts with no saves and the folders appear on first launch.
///
/// Accounts:
///   player              the normal account
///   testaccountsave     a test account that saves normally, in its own folder
///   testaccountnosave   a test account that never writes anything: it always starts from the beginning
///
/// A save holds: the card collection (owned counts), main + extra deck, max health, and world map progress
/// (which map, cleared fights, rewards taken, where you stand, side branches).

#macro SAVE_ROOT "saves"
#macro SAVE_SLOT_AUTO 1
#macro SAVE_SLOT_COUNT 4
#macro SAVE_VERSION 1
#macro SAVE_ACCOUNTS ["player", "testaccountsave", "testaccountnosave"]
#macro SAVE_ACCOUNT_NOSAVE "testaccountnosave"
#macro SAVE_MESSAGE_MS 2400

/// Session state: account, the slot being played, whether a game is running
function save_State() {
    if (!variable_global_exists("save") || !is_struct(global.save)) {
        global.save = {
            ready: false,
            account: "player",
            slot: -1,              // slot this game was loaded / started from (-1 = none)
            in_game: false,        // a game is loaded or started
            resume_room: -1,       // where "Continue" goes back to
            message: "",
            message_time: 0
        };
    }
    return global.save;
}

/// Game start: pick the last used account and make sure its save folder exists
function save_Init() {
    var _s = save_State();
    if (_s.ready) return;
    _s.ready = true;

    var _settings = data_ReadJsonFile(SAVE_ROOT + "/accounts.json");
    var _account = is_struct(_settings) ? struct_GetOr(_settings, "current", "player") : "player";
    if (!array_contains(SAVE_ACCOUNTS, _account)) _account = "player";
    _s.account = _account;
    save_EnsureAccount();
}

function save_Message(_text) {
    var _s = save_State();
    _s.message = _text;
    _s.message_time = current_time;
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

function save_AccountSaves(_account = save_State().account) {
    return _account != SAVE_ACCOUNT_NOSAVE;
}

function save_AccountDir(_account = save_State().account) {
    return SAVE_ROOT + "/" + _account;
}

/// First use of an account: create its folder and profile (never for the no-save test account)
function save_EnsureAccount() {
    var _account = save_State().account;
    if (!save_AccountSaves(_account)) return false;
    if (!directory_exists(SAVE_ROOT)) directory_create(SAVE_ROOT);
    var _dir = save_AccountDir(_account);
    if (!directory_exists(_dir)) directory_create(_dir);
    var _profile = _dir + "/profile.json";
    if (!file_exists(_profile)) {
        save_WriteJson(_profile, { account: _account, created: date_datetime_string(date_current_datetime()), version: SAVE_VERSION });
    }
    return true;
}

/// Switch account. The running game is closed (back to a fresh start); the choice is remembered.
function save_SetAccount(_account) {
    if (!array_contains(SAVE_ACCOUNTS, _account)) return false;
    var _s = save_State();
    _s.account = _account;
    _s.slot = -1;
    _s.in_game = false;
    _s.resume_room = -1;
    save_ResetToNewGame();
    if (!directory_exists(SAVE_ROOT)) directory_create(SAVE_ROOT);
    save_WriteJson(SAVE_ROOT + "/accounts.json", { current: _account });   // app setting, not account data
    save_EnsureAccount();
    save_Message("Account: " + _account);
    return true;
}

/// The next account in the list (for the home screen's Switch button)
function save_NextAccount() {
    var _list = SAVE_ACCOUNTS;
    var _i = 0;
    for (var k = 0; k < array_length(_list); k++) if (_list[k] == save_State().account) _i = k;
    return _list[(_i + 1) mod array_length(_list)];
}

// ---------------------------------------------------------------------------
// Files
// ---------------------------------------------------------------------------

function save_WriteJson(_path, _data) {
    var _f = file_text_open_write(_path);
    if (_f < 0) return false;
    file_text_write_string(_f, json_stringify(_data));
    file_text_close(_f);
    return true;
}

function save_SlotPath(_slot) {
    return save_AccountDir() + "/slot" + string(_slot) + ".json";
}

function save_SlotExists(_slot) {
    return save_AccountSaves() && file_exists(save_SlotPath(_slot));
}

/// The saved data in a slot, or undefined
function save_ReadSlot(_slot) {
    if (!save_SlotExists(_slot)) return undefined;
    var _data = data_ReadJsonFile(save_SlotPath(_slot));
    return is_struct(_data) ? _data : undefined;
}

/// Short description of a slot for the home screen: { exists, title, detail, time }
function save_SlotSummary(_slot) {
    var _title = (_slot == SAVE_SLOT_AUTO) ? "Slot 1  (Autosave)" : "Slot " + string(_slot);
    var _data = save_ReadSlot(_slot);
    if (_data == undefined) {
        return { exists: false, title: _title, detail: (_slot == SAVE_SLOT_AUTO) ? "Empty (saves itself as you play)" : "Empty: start a new game here", time: 0 };
    }
    var _sum = struct_GetOr(_data, "summary", {});
    var _detail = struct_GetOr(_sum, "map_name", "Deck builder")
        + "   " + string(struct_GetOr(_sum, "cleared", 0)) + "/" + string(struct_GetOr(_sum, "total", 0)) + " cleared"
        + "   " + string(struct_GetOr(_sum, "cards", 0)) + " cards"
        + "   " + struct_GetOr(_data, "saved_text", "");
    return { exists: true, title: _title, detail: _detail, time: struct_GetOr(_data, "saved_at", 0) };
}

/// The slot saved most recently, or -1. Uses each save's number ("seq", counted per account in
/// profile.json): the clock only has whole seconds, and an autosave + quick save can share one.
function save_NewestSlot() {
    var _best = -1;
    var _best_seq = -1;
    var _best_time = -1;
    for (var i = 1; i <= SAVE_SLOT_COUNT; i++) {
        var _data = save_ReadSlot(i);
        if (_data == undefined) continue;
        var _seq = struct_GetOr(_data, "seq", 0);
        var _t = struct_GetOr(_data, "saved_at", 0);
        if (_seq > _best_seq || (_seq == _best_seq && _t > _best_time)) {
            _best_seq = _seq;
            _best_time = _t;
            _best = i;
        }
    }
    return _best;
}

/// Next save number for this account (kept in profile.json)
function save_NextSeq() {
    var _path = save_AccountDir() + "/profile.json";
    var _profile = data_ReadJsonFile(_path);
    if (!is_struct(_profile)) _profile = { account: save_State().account, version: SAVE_VERSION };
    var _seq = struct_GetOr(_profile, "saves", 0) + 1;
    _profile.saves = _seq;
    save_WriteJson(_path, _profile);
    return _seq;
}

function save_AnySave() {
    return save_NewestSlot() >= 0;
}

// ---------------------------------------------------------------------------
// Game state <-> save data
// ---------------------------------------------------------------------------

function save_CopyArray(_a) {
    var _out = [];
    if (is_array(_a)) for (var i = 0; i < array_length(_a); i++) array_push(_out, _a[i]);
    return _out;
}

/// Everything a save holds, from the running game
function save_BuildSnapshot() {
    worldmap_InitGlobals();
    var _wm = global.worldmap;

    var _cards = [];
    var _owned_total = 0;
    if (variable_global_exists("player_collection") && is_array(global.player_collection)) {
        for (var i = 0; i < array_length(global.player_collection); i++) {
            var _c = global.player_collection[i];
            var _owned = struct_GetOr(_c, "owned", 0);
            array_push(_cards, { id: _c.id, collection: struct_GetOr(_c, "collection", ""), owned: _owned });
            _owned_total += _owned;
        }
    }

    // story fights cleared on the current map (for the slot summary)
    var _total = array_length(_wm.event_flow);
    var _cleared = 0;
    for (var e = 0; e < _total; e++) if (worldmap_IsEventCleared(_wm.event_flow[e])) _cleared++;

    var _map = {
        room: (_wm.return_room != noone && room_exists(_wm.return_room)) ? room_get_name(_wm.return_room) : "",
        config_file: _wm.config_file,
        cleared: save_CopyArray(_wm.cleared),
        rewards_obtained: save_CopyArray(_wm.rewards_obtained),
        side_branches: _wm.side_branches,
        side_next_id: _wm.side_next_id,
        side_pending: _wm.side_pending,
        node_pos: _wm.node_pos,
        node_map_key: _wm.node_map_key
    };
    if (is_struct(_wm.node_start)) _map.node_start = _wm.node_start;

    var _now = date_current_datetime();
    return {
        version: SAVE_VERSION,
        account: save_State().account,
        saved_at: _now,
        saved_text: date_datetime_string(_now),
        player_max_health: variable_global_exists("player_max_health") ? global.player_max_health : 100,
        collection: _cards,
        deck: battle_GetDeckSourceCopy(),
        extra_deck: battle_GetExtraDeckSourceCopy(),
        map: _map,
        summary: { map_name: (_wm.config_file != "") ? worldmap_GetMapDisplayName() : "Deck builder", cleared: _cleared, total: _total, cards: _owned_total }
    };
}

/// Back to the very beginning: starting cards, no deck, no map progress
function save_ResetToNewGame() {
    global.player_collection = [];
    global.player_collection_initialized = false;
    collection_EnsurePlayerInitialized();   // grants the cards JSON gives with "own"

    global.battle_deck_source = [];
    global.battle_extra_deck_source = [];
    global.battle_initial_main_deck = [];
    global.battle_runtime_config = undefined;
    global.player_max_health = 100;
    global.spawn_x = undefined;
    global.spawn_y = undefined;

    global.worldmap = 0;      // worldmap_InitGlobals builds a fresh one
    worldmap_InitGlobals();
    global.dialog = 0;        // dialog_Init builds a fresh one
    dialog_Init();
}

/// Put a save into the running game (does not change rooms)
function save_ApplySnapshot(_data) {
    save_ResetToNewGame();

    // cards: rebuilt from the card database, with the saved owned counts
    global.player_collection = [];
    var _cards = struct_GetOr(_data, "collection", []);
    for (var i = 0; i < array_length(_cards); i++) {
        var _def = collection_FindDefinition(_cards[i].id, struct_GetOr(_cards[i], "collection", ""));
        if (_def == undefined) continue;
        var _card = collection_CopyDefinition(_def);
        _card.owned = _cards[i].owned;
        array_push(global.player_collection, _card);
    }
    global.player_collection_initialized = true;

    global.battle_deck_source = save_CopyArray(struct_GetOr(_data, "deck", []));
    global.battle_extra_deck_source = save_CopyArray(struct_GetOr(_data, "extra_deck", []));
    global.player_max_health = struct_GetOr(_data, "player_max_health", 100);

    var _map = struct_GetOr(_data, "map", {});
    var _wm = global.worldmap;
    var _room = asset_get_index(struct_GetOr(_map, "room", ""));
    if (_room != -1 && room_exists(_room)) _wm.return_room = _room;
    _wm.config_file = struct_GetOr(_map, "config_file", "");
    _wm.cleared = save_CopyArray(struct_GetOr(_map, "cleared", []));
    _wm.rewards_obtained = save_CopyArray(struct_GetOr(_map, "rewards_obtained", []));
    _wm.side_branches = save_CopyArray(struct_GetOr(_map, "side_branches", []));
    _wm.side_next_id = struct_GetOr(_map, "side_next_id", _wm.side_next_id);
    _wm.side_pending = struct_GetOr(_map, "side_pending", -1);
    _wm.node_pos = struct_GetOr(_map, "node_pos", _wm.node_pos);
    _wm.node_map_key = struct_GetOr(_map, "node_map_key", "");
    var _start = struct_GetOr(_map, "node_start", undefined);
    _wm.node_start = is_struct(_start) ? _start : undefined;
}

/// Where a loaded / started game begins: the saved map, or the deck builder while the deck isn't ready
/// yet (fewer than the 8 cards READY needs, or no map reached so far)
function save_GameRoom() {
    if (array_length(battle_GetDeckSourceCopy()) < 8 || global.worldmap.config_file == "") return Room_collection;
    var _r = global.worldmap.return_room;
    return (_r != noone && room_exists(_r)) ? _r : Room_Worldmap1;
}

// ---------------------------------------------------------------------------
// Saving and loading
// ---------------------------------------------------------------------------

/// Write the running game to a slot. Returns true when it was written.
function save_WriteSlot(_slot) {
    if (!save_AccountSaves()) return false;
    if (_slot < 1 || _slot > SAVE_SLOT_COUNT) return false;
    save_EnsureAccount();
    var _snap = save_BuildSnapshot();
    _snap.seq = save_NextSeq();
    return save_WriteJson(save_SlotPath(_slot), _snap);
}

/// Autosave into slot 1 (called whenever a world map is entered)
function save_Autosave() {
    var _s = save_State();
    if (!_s.in_game || !save_AccountSaves()) return false;
    return save_WriteSlot(SAVE_SLOT_AUTO);
}

/// The manual slot Quick Save writes to: the one being played, else the first empty one, else slot 2
function save_QuickSaveSlot() {
    var _s = save_State();
    if (_s.slot > SAVE_SLOT_AUTO) return _s.slot;
    for (var i = SAVE_SLOT_AUTO + 1; i <= SAVE_SLOT_COUNT; i++) {
        if (!save_SlotExists(i)) return i;
    }
    return SAVE_SLOT_AUTO + 1;
}

function save_QuickSave() {
    var _s = save_State();
    if (!save_AccountSaves()) { save_Message(SAVE_ACCOUNT_NOSAVE + " never saves"); return false; }
    if (!_s.in_game) { save_Message("Nothing to save yet: press Play first"); return false; }
    var _slot = save_QuickSaveSlot();
    if (!save_WriteSlot(_slot)) { save_Message("Could not save"); return false; }
    _s.slot = _slot;
    save_Message("Saved to slot " + string(_slot));
    return true;
}

/// Load a slot and go to where that game was. Returns false when the slot is empty.
function save_LoadSlot(_slot) {
    var _data = save_ReadSlot(_slot);
    if (_data == undefined) return false;
    save_ApplySnapshot(_data);
    var _s = save_State();
    _s.slot = _slot;
    _s.in_game = true;
    save_Message("Loaded slot " + string(_slot));
    room_goto(save_GameRoom());
    return true;
}

/// Quick Load: the newest save of this account (the no-save test account just starts over)
function save_QuickLoad() {
    if (!save_AccountSaves()) {
        save_StartNewGame(-1);
        return true;
    }
    var _slot = save_NewestSlot();
    if (_slot < 0) { save_Message("No saves yet"); return false; }
    return save_LoadSlot(_slot);
}

/// A new game from the very beginning, saved into _slot (2-4) right away. Starts in the deck builder.
function save_StartNewGame(_slot) {
    save_ResetToNewGame();
    var _s = save_State();
    _s.slot = _slot;
    _s.in_game = true;
    if (_slot > 0 && save_AccountSaves()) save_WriteSlot(_slot);
    save_Message(save_AccountSaves() ? "New game in slot " + string(_slot) : "New game (" + SAVE_ACCOUNT_NOSAVE + ": nothing is saved)");
    room_goto(Room_collection);
}

function save_SaveAndExit() {
    if (save_State().in_game && save_AccountSaves()) save_QuickSave();
    game_end();
}

/// Open the home screen from inside the game ("Continue" comes back here)
function save_OpenHomeMenu() {
    save_State().resume_room = room;
    room_goto(Room_home);
}

/// "Continue": back into the running game
function save_Resume() {
    var _s = save_State();
    if (!_s.in_game) return false;
    var _r = _s.resume_room;
    if (_r == -1 || !room_exists(_r)) _r = save_GameRoom();
    room_goto(_r);
    return true;
}
