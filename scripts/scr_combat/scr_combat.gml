/// @desc Combat resolution shared by player and enemy: damage, unit death, attack stats.
///
/// combat_DamageUnit / combat_RemoveUnit are the ONLY places where units lose health or leave
/// the board, so every attack (weapons, action cards, spirits, enemy monsters) resolves the same way.

// ---------------------------------------------------------------------------
// Damage & death
// ---------------------------------------------------------------------------

/// Deal damage to one unit (or to the player when _slot is UNIT_HERO on the player side).
/// Back-row units guarded by a frontline take nothing (scr_card_targeting).
/// Player monsters that die pass leftover damage to the player (spirits never overflow).
function combat_DamageUnit(_side, _slot, _amount) {
    if (unit_IsGuarded(_side, _slot)) return false;
    if (_amount > 0) battlefx_Hit(_side, _slot);   // sword swing + blink on the target

    if (_side == SIDE_PLAYER && _slot == UNIT_HERO) {
        return battle_DamagePlayer(_amount);
    }

    var _card = unit_Get(_side, _slot);
    if (_card == undefined) return false;

    if (_side == SIDE_PLAYER) {
        battle_EnsureCardHealth(_card);
        var _hp_before = _card.health;
        _card.health = max(0, _card.health - _amount);
        if (_card.health <= 0) {
            var _overflow = 0;
            if (!card_IsSpiritType(_card)) {
                _overflow = max(0, _amount - _hp_before);
            }
            combat_RemoveUnit(SIDE_PLAYER, _slot);
            if (_overflow > 0) {
                battle_DamagePlayer(_overflow);
            }
        }
        return true;
    }

    _card.health = max(0, _card.health - _amount);
    if (_card.health <= 0) {
        combat_RemoveUnit(SIDE_ENEMY, _slot);
    }
    return true;
}

/// Remove a unit from the board (death / destroy / sacrifice / expiry / its back-row spot closing).
/// An enemy's spot stays empty until the next enemy turn, unless the next enemy in the queue has tag_in.
function combat_RemoveUnit(_side, _slot) {
    var _card = unit_Get(_side, _slot);
    if (_card == undefined) return false;
    var _board = instance_find(OBJ_BoardManager, 0);
    battlefx_Death(_side, _slot);   // a pile of bones where it stood

    if (_side == SIDE_ENEMY) {
        var _mm = instance_find(OBJ_MonsterManager, 0);
        monsterAbility_OnDeath(_card);
        var _eslot = _board.enemy_slots[_slot];
        _eslot.occupied = false;
        _eslot.card = undefined;
        global.battlefx_spawn_delay = BATTLEFX_REPLACE_DELAY + global.battlefx_hit_delay;   // a tag_in enemy waits for the blow and the bones
        with (_mm) {
            monster_OnSlotEmptied(_board, _slot);
            monster_TagInFreeSlots(_board, _slot);
            monster_CheckVictory(_board);
        }
        global.battlefx_spawn_delay = -1;
        return true;
    }

    battle_CloseBackRowSpotsOf(_slot);   // back-row spots this monster opened close, and whoever stands there leaves

    var _monster_slot = _board.player_monster_slots[_slot];

    if (card_IsSpiritType(_card)) {
        if (card_IsAstral(_card)) {
            battle_PermanentlyLoseSpirit(_card);
        } else {
            _card.spirit_temp_consumed = true;
        }
    }

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone) {
        with (_bm) {
            battle_ClearResourceEffectsFromSlot(_slot);
            if (_slot == pending_player_slot) battle_CancelTargeting();
            if (_slot < array_length(weapon_attacks_used)) {
                weapon_attacks_used[_slot] = 0;
            }
        }
    }

    with (_board) {
        var _weapon_slot = player_weapon_slots[_slot];
        if (_weapon_slot.occupied && _weapon_slot.card != undefined) {
            SCR_Board_RemoveCard(_weapon_slot);
        }
        SCR_Board_RemoveCard(_monster_slot);
    }
    return true;
}

// ---------------------------------------------------------------------------
// Attack stats
// ---------------------------------------------------------------------------

function card_GainAttack(_card, _amount) {
    if (_card == undefined || _amount <= 0) return;

    if (!variable_struct_exists(_card, "attack")) _card.attack = 0;
    if (!variable_struct_exists(_card, "attack_buff")) _card.attack_buff = 0;

    _card.attack += _amount;
    _card.attack_buff += _amount;
}

/// Remove attack that was granted earlier (timed buffs expiring)
function card_LoseAttack(_card, _amount) {
    if (_card == undefined) return;
    _card.attack = max(0, _card.attack - _amount);
    if (variable_struct_exists(_card, "attack_buff")) {
        _card.attack_buff = max(0, _card.attack_buff - _amount);
    }
}

function card_GetAttackBuff(_card) {
    if (_card == undefined) return 0;
    if (!variable_struct_exists(_card, "attack_buff")) return 0;
    return max(0, floor(_card.attack_buff));
}

/// Attack of a card on its own: enemies their attack (buffs included), weapons their strike,
/// your monsters their own attack + buffs (no weapon — see battle_GetPlayerMonsterSummaryAttack for the column)
function card_GetSummaryTotalAttack(_card) {
    if (_card == undefined) return 0;

    if (variable_struct_exists(_card, "base_attack")) {   // enemy
        if (variable_struct_exists(_card, "attack")) return max(0, floor(_card.attack));
        return max(0, floor(_card.base_attack)) + card_GetAttackBuff(_card);
    }

    if (_card.type == "weapon") return weapon_GetAttackAmount(_card);
    return battle_GetMonsterStrikeAmount(_card);
}

/// ATK number shown on the battlefield. Your monsters show their column strike (monster + weapon + buffs).
function card_GetBoardAttackDisplay(_card, _column = -1) {
    if (_card == undefined) return 0;

    if (variable_struct_exists(_card, "base_attack")) {   // enemy
        var _total = max(0, floor(_card.base_attack)) + card_GetAttackBuff(_card);
        if (variable_struct_exists(_card, "attack")) {
            _total = max(_total, max(0, floor(_card.attack)));
        }
        return _total;
    }

    return battle_GetPlayerMonsterSummaryAttack(_card, _column);
}

function card_DrawAttackGainBadge(_x, _y, _w, _h, _amount) {
    if (_amount <= 0) return;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_red);
    draw_text(_x + _w / 2, _y + _h / 2 + 2, "+" + string(_amount));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

/// Amount of the first trait of a type on a card (0 when missing or not positive)
function card_GetTraitAmount(_card, _type) {
    if (_card == undefined) return 0;
    var _trait = trait_FindFirst(trait_GetFromCard(_card), _type);
    if (_trait != undefined && _trait.amount > 0) return floor(_trait.amount);
    return 0;
}

/// Your monster's own attack including buffs (no weapon)
function battle_GetMonsterStrikeAmount(_card) {
    if (_card == undefined) return 0;
    return battle_GetMonsterBaseStrikeAmount(_card) + card_GetAttackBuff(_card);
}

/// Your monster's own attack without buffs: its JSON "attack" (default 0), or else an "attack" trait (spirits).
/// card.attack holds the JSON attack plus every buff (card_GainAttack), so the buffs are taken back off.
function battle_GetMonsterBaseStrikeAmount(_card) {
    if (_card == undefined) return 0;

    var _base = 0;
    if (variable_struct_exists(_card, "attack")) {
        _base = floor(real(_card.attack)) - card_GetAttackBuff(_card);
    }
    if (_base <= 0) _base = card_GetTraitAmount(_card, "attack");
    return max(0, _base);
}

function battle_GetPlayerMonsterSummaryAttack(_card, _column = -1) {
    if (_column < 0) _column = battle_FindPlayerMonsterColumn(_card);
    if (_column >= 0) {
        return battle_ColumnSingleStrikeTotal(battle_GetColumnStrikeParts(_column));
    }
    return card_GetSummaryTotalAttack(_card);
}

function battle_FindPlayerMonsterColumn(_card) {
    return unit_FindSlotOfCard(SIDE_PLAYER, _card);
}

// ---------------------------------------------------------------------------
// Player columns (monster + weapon below it)
//
// Damage of an attack = the monster's attack + its weapon's attack + attack buffs
//                       (+ the action card's amount when an action card makes the attack).
// A monster can only attack with a weapon equipped or through an action card;
// extra-deck spirits can also strike on their own.
// ---------------------------------------------------------------------------

function battle_GetColumnStrikeParts(_column) {
    var _parts = {
        monster_strike: 0,
        weapon_strike: 0,
        monster_attack_all: 0,
        weapon_attack_all: 0,
        buff: 0,
        has_weapon: false,
        armed: false          // may strike from the column: a weapon is equipped, or the monster is a spirit
    };

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return _parts;
    if (_column < 0 || _column >= array_length(_board.player_monster_slots)) return _parts;

    var _monster_slot = _board.player_monster_slots[_column];
    var _weapon_slot = _board.player_weapon_slots[_column];

    if (_monster_slot.visible && _monster_slot.occupied && _monster_slot.card != undefined) {
        _parts.monster_strike = battle_GetMonsterBaseStrikeAmount(_monster_slot.card);
        _parts.monster_attack_all = card_GetTraitAmount(_monster_slot.card, "attack_all");
        _parts.buff = card_GetAttackBuff(_monster_slot.card);
    }

    if (_weapon_slot.visible && _weapon_slot.occupied && _weapon_slot.card != undefined) {
        _parts.has_weapon = true;
        _parts.weapon_strike = weapon_GetAttackAmount(_weapon_slot.card);
        _parts.weapon_attack_all = card_GetTraitAmount(_weapon_slot.card, "attack_all");
    }

    _parts.armed = _parts.has_weapon || card_IsSpiritType(_monster_slot.card);
    return _parts;
}

/// Weapon / spirit strike: monster attack + weapon attack + buffs
function battle_ColumnSingleStrikeTotal(_parts) {
    return _parts.monster_strike + _parts.weapon_strike + _parts.buff;
}

/// Action card attack: the action's amount + monster attack + weapon attack + buffs
function battle_ColumnActionStrikeTotal(_parts, _action_amount) {
    return max(0, _action_amount) + battle_ColumnSingleStrikeTotal(_parts);
}

function battle_ColumnWeaponAttackAllTotal(_parts) {
    return _parts.weapon_attack_all + _parts.monster_strike + _parts.buff;
}

function battle_ColumnMonsterAttackAllTotal(_parts) {
    return _parts.monster_attack_all + _parts.weapon_strike + _parts.buff;
}

// ---------------------------------------------------------------------------
// Weapon data
// ---------------------------------------------------------------------------

function weapon_GetAttackAmount(_card) {
    if (_card == undefined) return 0;

    weapon_EnsureAttackData(_card);

    if (variable_struct_exists(_card, "attack") && _card.attack > 0) {
        return floor(_card.attack);
    }
    return card_GetTraitAmount(_card, "attack");
}

function weapon_EnsureRecursionData(_card) {
    if (_card == undefined || _card.type != "weapon") return;

    if (!variable_struct_exists(_card, "attackRecursion")) {
        _card.attackRecursion = 1;
    } else {
        _card.attackRecursion = max(0, floor(real(_card.attackRecursion)));
    }

    if (!variable_struct_exists(_card, "effectRecursion")) {
        _card.effectRecursion = 1;
    } else {
        _card.effectRecursion = max(1, floor(real(_card.effectRecursion)));
    }
}

function weapon_GetAttackRecursion(_card) {
    if (_card == undefined) return 1;
    weapon_EnsureRecursionData(_card);
    return _card.attackRecursion;
}

function weapon_EnsureAttackData(_card) {
    if (_card == undefined || _card.type != "weapon") return;

    weapon_EnsureRecursionData(_card);

    var _atk = 0;
    if (variable_struct_exists(_card, "attack")) _atk = real(_card.attack);

    if (_atk <= 0 && variable_struct_exists(_card, "ability") && is_array(_card.ability)) {
        for (var i = 0; i < array_length(_card.ability); i++) {
            var _entry = _card.ability[i];
            if (!variable_struct_exists(_entry, "type") || _entry.type != "attack") continue;
            if (variable_struct_exists(_entry, "amount")) _atk = real(_entry.amount);
            else if (variable_struct_exists(_entry, "value")) _atk = real(_entry.value);
            break;
        }
    }

    if (_atk <= 0) _atk = 1;
    _card.attack = floor(_atk);

    if (!variable_struct_exists(_card, "ability") || !is_array(_card.ability)) {
        _card.ability = [];
    }

    var _found = false;
    for (var j = 0; j < array_length(_card.ability); j++) {
        if (_card.ability[j].type != "attack") continue;
        _card.ability[j].amount = _card.attack;
        // "repeat" is a GML keyword, so the field is read/written with [$ "repeat"]
        if (!variable_struct_exists(_card.ability[j], "repeat")) {
            _card.ability[j][$ "repeat"] = (_card.attackRecursion > 0);
        }
        if (!variable_struct_exists(_card.ability[j], "recursion")) {
            _card.ability[j].recursion = max(1, _card.attackRecursion);
        }
        _card.ability[j].uses_per_turn = _card.ability[j][$ "repeat"] ? _card.ability[j].recursion : 0;
        _found = true;
        break;
    }

    if (!_found) {
        var _attack = {
            type: "attack",
            amount: _card.attack,
            recursion: max(1, _card.attackRecursion),
            uses_per_turn: (_card.attackRecursion > 0) ? max(1, _card.attackRecursion) : 0
        };
        _attack[$ "repeat"] = (_card.attackRecursion > 0);
        array_push(_card.ability, _attack);
    }
}
