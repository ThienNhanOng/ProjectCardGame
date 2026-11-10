/// @desc OBJ_MonsterManager — wave queue, spawning, victory check

function SCR_Monster_Init() {
    battle_won = false;
    monster_queue = [];
    hovered_enemy_slot = -1;
    active_slot_count = 0;
    battle_name = "";

    battle_EnsureMonsterDatabase();

    var _config = undefined;

    if (variable_global_exists("battle_runtime_config") && global.battle_runtime_config != undefined) {
        _config = global.battle_runtime_config;
    } else {
        var _battle_file = "Battle01.json";
        if (variable_global_exists("battle_config_file")) {
            _battle_file = global.battle_config_file;
        }
        _config = battle_LoadConfig(_battle_file);
    }

    if (_config == undefined) {
        return;
    }

    battle_name = _config.battle;
    active_slot_count = _config.active_slots;

    battle_EnemyLog_Init();

    for (var i = 0; i < array_length(_config.wave); i++) {
        array_push(monster_queue, _config.wave[i]);
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) {
        return;
    }

    monster_ApplyActiveSlotLayout(_board);
    monster_FillActiveSlots(_board);

    var _living = monster_CountLivingActive(_board);
}

function monster_ApplyActiveSlotLayout(_board) {
    for (var i = 0; i < array_length(_board.enemy_slots); i++) {
        var _slot = _board.enemy_slots[i];
        var _active = (i < active_slot_count);

        _slot.visible = _active;
        if (!_active) {
            _slot.occupied = false;
            _slot.card = undefined;
        }
    }
}

function monster_SpawnIntoSlot(_board, _slot_index) {
    if (_slot_index >= active_slot_count) return false;
    if (array_length(monster_queue) <= 0) return false;

    var _entry = monster_queue[0];
    array_delete(monster_queue, 0, 1);

    var _monster = monster_CreateInstance(_entry);
    if (_monster == undefined) {
        array_insert(monster_queue, 0, _entry);
        return false;
    }

    var _slot = _board.enemy_slots[_slot_index];
    _slot.occupied = true;
    _slot.visible = true;
    _slot.card = _monster;
    var _bm_turn = instance_find(OBJ_BattleManager, 0);
    _monster.spawn_turn = (_bm_turn != noone && variable_instance_exists(_bm_turn, "turn_number")) ? _bm_turn.turn_number : 1;   // stage sprites count turns from here
    battlefx_Arrive(_monster, SIDE_ENEMY, _slot_index, battlefx_SpawnDelay(_slot_index));   // hops in from the right

    return true;
}

function monster_FillActiveSlots(_board) {
    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (_slot.occupied && _slot.card != undefined && _slot.card.alive) continue;
        if (!monster_SpawnIntoSlot(_board, i)) break;
    }

    monster_CheckVictory(_board);
}

function monster_CheckVictory(_board) {
    if (array_length(monster_queue) > 0) {
        battle_won = false;
        return;
    }

    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (_slot.occupied && _slot.card != undefined && _slot.card.alive) {
            battle_won = false;
            return;
        }
    }

    battle_won = true;
    worldmap_NotifyBattleVictory();
}

// ---------------------------------------------------------------------------
// Hatching: an enemy with "hatch": { "turns": N, "into": [ {collection, enemyID}, ... ] }
// turns into one of the "into" enemies (random pick) at the end of the enemy turn once it has been
// on the field N turns (an egg's last crack stage is the warning).
// ---------------------------------------------------------------------------

function monster_HatchReady() {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_board == noone || _bm == noone) return;
    for (var i = 0; i < array_length(_board.enemy_slots); i++) {
        var _slot = _board.enemy_slots[i];
        var _m = _slot.card;
        if (!_slot.occupied || _m == undefined || !_m.alive) continue;
        if (!variable_struct_exists(_m, "hatch") || !is_struct(_m.hatch)) continue;
        var _turns = variable_struct_exists(_m.hatch, "turns") ? _m.hatch.turns : 4;
        var _age = _bm.turn_number - (variable_struct_exists(_m, "spawn_turn") ? _m.spawn_turn : 1);
        if (_age >= _turns) monster_Hatch(i);
    }
}

/// Replace the enemy in slot _slot_index with what it hatches into
function monster_Hatch(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    var _slot = _board.enemy_slots[_slot_index];
    var _egg = _slot.card;
    var _into = _egg.hatch.into;
    if (!is_array(_into) || array_length(_into) <= 0) return false;
    var _pick = _into[irandom(array_length(_into) - 1)];
    var _new = monster_CreateInstance({ collection: monster_NormalizeCollectionName(_pick.collection), enemyID: floor(_pick.enemyID) });
    if (_new == undefined) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    _new.spawn_turn = (_bm != noone) ? _bm.turn_number : 1;
    _slot.card = _new;
    battlefx_Hatch(_new, _slot_index);
    battle_EnemyLog_Action(_egg.name + " hatched into " + _new.name + "!");
    return true;
}

// ---------------------------------------------------------------------------
// Profiles: a set of stats an enemy can switch into. JSON:
//   { "name": "Jodan", "sprite": "SPR_X", "attack": 9, "ability": [ ... ], "anim": 2, "weight": 1 }
// every field is optional:
//   sprite   new sprite set (SPR_X_Idle / SPR_X_Attack ...)
//   attack   new base attack (active buffs stay on top)
//   ability  replaces the ability list (not while silenced)
//   anim     which attack animation plays: 1 = _Attack, 2 = _Attack2, ...
//   weight   how likely a random pick is (default 1)
// Two lists use them:
//   "stances"  one is held at a time; a new one is taken at the end of every enemy turn
//   "moves"    one is picked at the start of each of the enemy's turns (its attack for that turn)
// ---------------------------------------------------------------------------

function monster_HasProfiles(_m, _list_name) {
    var _list = struct_GetOr(_m, _list_name, undefined);
    return is_array(_list) && array_length(_list) > 0;
}

/// Apply one profile's fields to an enemy instance
function monster_ApplyProfile(_m, _p) {
    if (variable_struct_exists(_p, "sprite")) _m.sprite_name = _p.sprite;
    if (variable_struct_exists(_p, "attack")) {
        _m.base_attack = _p.attack;
        _m.attack = _m.base_attack + card_GetAttackBuff(_m);   // keep active buffs
    }
    if (variable_struct_exists(_p, "ability") && !status_IsSilenced(_m)) {
        _m.ability = status_CloneAbilityArray(_p.ability);
        _m.ability_index = 0;
    }
    _m.anim_attack_fixed = variable_struct_exists(_p, "anim") ? floor(_p.anim) - 1 : -1;
}

/// Can this profile be picked right now? Optional "when":
///   "free_slot"   only while an enemy spot is empty (e.g. laying an egg / summoning)
function monster_ProfileUsable(_p) {
    switch (struct_GetOr(_p, "when", "")) {
        case "free_slot": return unit_Count(SIDE_ENEMY) < unit_GetSlotCount(SIDE_ENEMY);
    }
    return true;
}

/// Weighted random index into a profile list: skips profiles that cannot be used now, and _avoid
/// (the current one) when anything else is possible. -1 only for an empty list.
function monster_PickProfileIndex(_list, _avoid = -1) {
    var _n = array_length(_list);
    if (_n <= 0) return -1;
    var _weights = array_create(_n, 0);
    var _total = 0;
    for (var pass = 0; pass < 2 && _total <= 0; pass++) {     // pass 1 also allows repeating _avoid
        for (var i = 0; i < _n; i++) {
            var _w = monster_ProfileUsable(_list[i]) ? max(0, struct_GetOr(_list[i], "weight", 1)) : 0;
            if (pass == 0 && i == _avoid) _w = 0;
            _weights[i] = _w;
            _total += _w;
        }
    }
    if (_total <= 0) return max(0, _avoid);
    var _roll = random(_total);
    for (var j = 0; j < _n; j++) {
        _roll -= _weights[j];
        if (_roll < 0) return j;
    }
    return _n - 1;
}

/// Start of an enemy's turn: an enemy with "moves" picks this turn's move
function monster_ChooseMove(_m) {
    if (!monster_HasProfiles(_m, "moves")) return false;
    var _index = monster_PickProfileIndex(_m.moves, _m.move_index);
    var _move = _m.moves[_index];
    monster_ApplyProfile(_m, _move);
    _m.move_index = _index;
    _m.move_name = struct_GetOr(_move, "name", "");
    if (_m.move_name != "") battle_EnemyLog_Action(_m.name + " readies " + _m.move_name + " (ATK " + string(_m.attack) + ").");
    return true;
}

/// Put _m into stance number _index; _announce logs it with a smoke puff
function monster_ApplyStance(_m, _index, _announce, _slot_index = -1) {
    if (!monster_HasProfiles(_m, "stances") || _index < 0 || _index >= array_length(_m.stances)) return false;
    var _st = _m.stances[_index];
    monster_ApplyProfile(_m, _st);
    _m.stance_index = _index;
    _m.stance_name = struct_GetOr(_st, "name", "");
    variable_struct_remove(_m, "anim_attack_start");
    if (_announce) {
        battle_EnemyLog_Action(_m.name + " shifts into " + _m.stance_name + " stance!");
        if (_slot_index >= 0) {
            battlefx_Init();
            var _f = battlefx_UnitFeet(SIDE_ENEMY, _slot_index);
            if (_f != undefined) array_push(global.battle_fx, { type: "smoke", x: _f.x, y: _f.y, start: current_time });
        }
    }
    return true;
}

/// End of the enemy turn: every living stance user swaps to a different random stance
function monster_StanceSwapAll() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;
    for (var i = 0; i < array_length(_board.enemy_slots); i++) {
        var _slot = _board.enemy_slots[i];
        var _m = _slot.card;
        if (!_slot.occupied || _m == undefined || !_m.alive) continue;
        if (!monster_HasProfiles(_m, "stances") || array_length(_m.stances) < 2) continue;
        monster_ApplyStance(_m, monster_PickProfileIndex(_m.stances, _m.stance_index), true, i);   // never the same stance twice in a row
    }
}

function monster_GetQueueCount() {
    return array_length(monster_queue);
}

function monster_QueueInsertFront(_entry) {
    if (_entry == undefined) return false;

    var _mm = instance_find(OBJ_MonsterManager, 0);
    if (_mm == noone) return false;

    var _board = instance_find(OBJ_BoardManager, 0);

    with (_mm) {
        if (!variable_instance_exists(id, "monster_queue") || !is_array(monster_queue)) {
            monster_queue = [];
        }

        array_insert(monster_queue, 0, _entry);

        if (_board != noone) {
            monster_FillActiveSlots(_board);
        }

    }

    return true;
}

function monster_CountLivingActive(_board) {
    var _count = 0;
    for (var i = 0; i < active_slot_count; i++) {
        var _slot = _board.enemy_slots[i];
        if (_slot.occupied && _slot.card != undefined && _slot.card.alive) {
            _count++;
        }
    }
    return _count;
}
