/// @desc Playing player cards — on-play traits, action cards, and the pending (targeted) trait.
/// Runs on OBJ_BattleManager.
///
/// Every card that needs a target (monster on-play, weapon on-play, action card) goes through the
/// same "pending trait" path:  pick target -> battle_ExecutePendingTrait -> battle_ContinueAfterPendingTrait.

// ---------------------------------------------------------------------------
// Card placed on the board
// ---------------------------------------------------------------------------

/// _defer_on_play: a monster summoned by another card plays its abilities after that card is done
function battle_NotifyCardPlaced(_slot, _card, _defer_on_play = false) {
    if (_slot == undefined || _card == undefined) return;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        switch (_slot.type) {
            case "monster":
                battle_InitBoardMonsterLifespan(_card);
                if (_defer_on_play) {
                    battle_EnsureCardHealth(_card);
                    array_push(battle_deferred_on_play, { slot: _slot.index, card: _card });
                } else {
                    battle_OnBoardCardPlayed("monster", _slot.index, _card);
                }
                break;
            case "action":
                battle_OnActionCardPlayed(_card);
                break;
            case "weapon":
                battle_OnBoardCardPlayed("weapon", _slot.index, _card);
                break;
        }
    }
}

/// Monster or weapon placed: run its automatic traits, then ask for targets for the rest.
/// _kind: "monster" | "weapon"
function battle_OnBoardCardPlayed(_kind, _slot_index, _card) {
    if (_kind == "monster") battle_EnsureCardHealth(_card);
    battle_CancelTargeting();
    trait_ChainReset();
    if (_kind == "weapon") weapon_EnsureAttackData(_card);

    var _traits = trait_GetFromCard(_card);
    for (var i = 0; i < array_length(_traits); i++) {
        var _trait = _traits[i];
        if (_trait.effect == "attack") continue;     // a board card's attack is its strike, not an on-play effect
        if (trait_OnPlayNeedsTarget(_trait)) continue;
        trait_ExecuteOnPlay(_trait, _slot_index);
    }

    battle_BeginOnPlayTargeting(_kind, _slot_index);
}

/// Card standing in a player monster slot ("monster") or weapon slot ("weapon"), or undefined
function battle_GetBoardSourceCard(_kind, _slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return undefined;

    var _slots = (_kind == "weapon") ? _board.player_weapon_slots : _board.player_monster_slots;
    if (_slot_index < 0 || _slot_index >= array_length(_slots)) return undefined;

    var _slot = _slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined) return undefined;
    return _slot.card;
}

/// Monsters summoned by another card (summon): they count as played once that card's play is done.
/// Runs from the battle Step while nothing is being targeted. True when one ran.
function battle_RunDeferredOnPlay() {
    if (array_length(battle_deferred_on_play) <= 0) return false;

    var _next = battle_deferred_on_play[0];
    array_delete(battle_deferred_on_play, 0, 1);
    if (unit_Get(SIDE_PLAYER, _next.slot) != _next.card) return false;   // it already left the board

    battle_OnBoardCardPlayed("monster", _next.slot, _next.card);
    return true;
}

function battle_BeginOnPlayTargeting(_kind, _slot_index, _start_trait_index = 0) {
    var _card = battle_GetBoardSourceCard(_kind, _slot_index);
    if (_card == undefined) return;

    var _traits = trait_GetFromCard(_card);
    for (var i = _start_trait_index; i < array_length(_traits); i++) {
        if (!trait_OnPlayNeedsTarget(_traits[i])) continue;
        if (trait_GetOnPlayPick(_traits[i]) == "spot" && !battle_CanSummon(_traits[i])) continue;   // nowhere to summon

        pending_trait_source = _kind + "_on_play";
        if (_kind == "weapon") pending_weapon_slot = _slot_index;
        else pending_monster_slot = _slot_index;
        pending_monster_trait_index = i;
        battle_BeginOnPlayTargetMode(_traits[i]);
        return;
    }

    battle_CancelTargeting();
    trait_ChainFinish();
}

function battle_OnPlayContinue(_kind, _slot_index, _completed_trait_index) {
    battle_BeginOnPlayTargeting(_kind, _slot_index, _completed_trait_index + 1);
    if (!battle_IsTargeting()) {
        trait_ChainFinish();
    }
}

/// Weapons' repeatable automatic traits fire again at the start of each player turn
function battle_RefreshWeaponRepeatableEffects() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return;

    for (var col = 0; col < array_length(_board.player_weapon_slots); col++) {
        var _wslot = _board.player_weapon_slots[col];
        if (!_wslot.visible || !_wslot.occupied || _wslot.card == undefined) continue;

        weapon_EnsureAttackData(_wslot.card);
        var _traits = trait_GetFromCard(_wslot.card);

        for (var i = 0; i < array_length(_traits); i++) {
            var _trait = _traits[i];
            if (_trait.effect == "attack") continue;
            if (!trait_IsRepeatable(_trait)) continue;
            if (trait_OnPlayNeedsTarget(_trait)) continue;

            var _times = trait_GetRecursionLimit(_trait);
            for (var r = 0; r < _times; r++) {
                trait_ExecuteOnPlay(_trait, col);
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Pending trait (a trait waiting for the player to pick its target)
// ---------------------------------------------------------------------------

/// { trait, index, source } for the trait waiting for a target, or undefined
function battle_GetPendingTraitInfo() {
    var _traits = [];
    var _index = -1;
    var _source_slot = -1;

    switch (pending_trait_source) {
        case "action":
            _traits = battle_GetActionTraits();
            _index = pending_action_trait_index;
            _source_slot = pending_player_slot;
            break;
        case "monster_on_play":
            var _mcard = battle_GetBoardSourceCard("monster", pending_monster_slot);
            if (_mcard == undefined) return undefined;
            _traits = trait_GetFromCard(_mcard);
            _index = pending_monster_trait_index;
            _source_slot = pending_monster_slot;
            break;
        case "weapon_on_play":
            var _wcard = battle_GetBoardSourceCard("weapon", pending_weapon_slot);
            if (_wcard == undefined) return undefined;
            _traits = trait_GetFromCard(_wcard);
            _index = pending_monster_trait_index;
            _source_slot = pending_weapon_slot;
            break;
        default:
            return undefined;
    }

    if (_index < 0 || _index >= array_length(_traits)) return undefined;
    return { trait: _traits[_index], index: _index, source: effect_Source(SIDE_PLAYER, _source_slot) };
}

/// Run the pending trait on the picked targets. Action cards spend one use of the trait when it succeeds.
function battle_ExecutePendingTrait(_targets) {
    var _is_action = (pending_trait_source == "action");
    if (_is_action && !battle_CanUseActionTrait(pending_action_trait_index)) return false;

    var _info = battle_GetPendingTraitInfo();
    if (_info == undefined) return false;
    if (!trait_Execute(_info.trait, trait_CreateContext(_info.source, _targets))) return false;

    if (_is_action) battle_ConsumeActionTrait(_info.index);
    return true;
}

/// After the pending trait resolved, move on to the card's next trait
function battle_ContinueAfterPendingTrait() {
    switch (pending_trait_source) {
        case "monster_on_play":
            battle_OnPlayContinue("monster", pending_monster_slot, pending_monster_trait_index);
            break;
        case "weapon_on_play":
            battle_OnPlayContinue("weapon", pending_weapon_slot, pending_monster_trait_index);
            break;
        case "action":
            battle_TargetingContinueAfterAction(pending_action_trait_index);
            break;
    }
}

function battle_ResolvePendingTrait(_targets) {
    if (!battle_ExecutePendingTrait(_targets)) return false;
    battle_ContinueAfterPendingTrait();
    return true;
}

/// Action attack / attack_all: the attacking monster was chosen into pending_player_slot
function battle_PendingAttackerCanAttack() {
    var _attacker = unit_Get(SIDE_PLAYER, pending_player_slot);
    return _attacker != undefined && !status_IsShrouded(_attacker);
}

/// Damage of the attack action card your monster in _column is about to use (for its ATK label), or -1:
///   - an action attack is choosing its attacker: every monster that could attack shows it
///   - the attacker is chosen: only that monster
///   - you are dragging an attack action card onto this monster
function battle_GetPreviewActionAttack(_column) {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm != noone && _bm.pending_trait_source == "action") {
        var _amount = -1;
        with (_bm) {
            var _info = battle_GetPendingTraitInfo();
            if (_info != undefined && _info.trait.effect == "attack") {
                if (target_mode == "pick_player_monster" && !battle_IsPlayerMonsterSlotShrouded(_column)) _amount = _info.trait.amount;
                if (target_mode == "pick_enemy" && pending_player_slot == _column) _amount = _info.trait.amount;
            }
        }
        if (_amount >= 0) return _amount;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.is_dragging && _board.drag_card != undefined && _board.drag_card.type == "action") {
        var _target = undefined;
        with (_board) _target = SCR_Board_GetDropTarget(mouse_x, mouse_y, drag_card);
        if (_target != undefined && _target.monster == _column) {
            var _traits = trait_GetFromCard(_board.drag_card);
            for (var i = 0; i < array_length(_traits); i++) {
                if (_traits[i].effect == "attack") return _traits[i].amount;
            }
        }
    }
    return -1;
}

/// Action attack / attack_all: damage = the action's amount + the attacking monster's attack
/// + its weapon's attack + its attack buffs (battle_ColumnActionStrikeTotal).
/// _type "attack" hits _targets; "attack_all" hits every enemy.
function battle_ExecuteActionAttack(_type, _targets = []) {
    if (!battle_CanUseActionTrait(pending_action_trait_index)) return false;
    if (!battle_PendingAttackerCanAttack()) return false;

    var _info = battle_GetPendingTraitInfo();
    if (_info == undefined || _info.trait.type != _type) return false;

    var _total = battle_ColumnActionStrikeTotal(battle_GetColumnStrikeParts(pending_player_slot), _info.trait.amount);
    if (_type == "attack_all") _targets = targets_All(SIDE_ENEMY);
    battlefx_PlayerAttack(pending_player_slot, _targets);   // the attacking monster runs up; the blow lands when it arrives
    var _hit = card_Damage(_info.source, _targets, _total);
    battlefx_EndDelay();
    if (!_hit) return false;

    battle_ConsumeActionTrait(_info.index);
    return true;
}

// ---------------------------------------------------------------------------
// Target modes
// ---------------------------------------------------------------------------

/// Target mode for a pick ("ally", "any", "enemy", "attacker", "spot"). The named modes keep their
/// own on-screen prompts; any other effect uses the generic pick_*_effect modes.
function battle_GetPickMode(_pick, _type) {
    switch (_pick) {
        case "spot": return "pick_free_spot";
        case "attacker": return "pick_player_monster";
        case "ally":
            if (_type == "heal") return "pick_player_heal";
            if (_type == "self_buff") return "pick_player_self_buff";
            return "pick_player_effect";
        case "any":
            if (_type == "buff") return "pick_any_buff";
            return "pick_any_effect";
        case "enemy":
            if (_type == "destroy") return "pick_enemy_destroy";
            if (_type == "silence") return "pick_enemy_silence";
            return "pick_enemy_effect";
    }
    return "none";
}

function battle_BeginOnPlayTargetMode(_trait) {
    target_mode = battle_GetPickMode(trait_GetOnPlayPick(_trait), _trait.type);
    if (target_mode == "none") battle_CancelTargeting();
}

function battle_BeginActionTargeting(_trait_index, _trait) {
    pending_trait_source = "action";
    pending_action_trait_index = _trait_index;
    pending_player_slot = -1;

    target_mode = battle_GetPickMode(trait_GetActionPick(_trait), _trait.type);
    if (target_mode == "none") battle_CancelTargeting();
}

// ---------------------------------------------------------------------------
// Action cards
// ---------------------------------------------------------------------------

function battle_GetActionTraits() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || !_board.action_slot.occupied) return [];
    return trait_GetFromCard(_board.action_slot.card);
}

function battle_RefreshActionUses() {
    action_trait_uses = [];

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone || !_board.action_slot.occupied || _board.action_slot.card == undefined) return;

    var _traits = trait_GetFromCard(_board.action_slot.card);
    for (var i = 0; i < array_length(_traits); i++) {
        if (trait_IsRepeatable(_traits[i])) {
            array_push(action_trait_uses, trait_GetRecursionLimit(_traits[i]));
        } else if (trait_ActionIsAuto(_traits[i])) {
            array_push(action_trait_uses, 0);
        } else {
            array_push(action_trait_uses, 1);
        }
    }
}

function battle_CanUseActionTrait(_trait_index) {
    if (!battle_IsPlayerPhase()) return false;
    if (battle_IsPlayerDefeated()) return false;
    if (_trait_index < 0 || _trait_index >= array_length(action_trait_uses)) return false;
    return action_trait_uses[_trait_index] > 0;
}

function battle_ConsumeActionTrait(_trait_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;
    action_trait_uses[_trait_index]--;
    action_card_used = true;
    return true;
}

/// Repeatable automatic action traits (they spend uses)
function battle_ExecuteActionTraitInstant(_trait_index) {
    if (!battle_CanUseActionTrait(_trait_index)) return false;

    var _traits = battle_GetActionTraits();
    if (_trait_index >= array_length(_traits)) return false;

    var _trait = _traits[_trait_index];
    var _supported = trait_IsAutoUnitEffect(_trait) && _trait.target != "self";
    switch (_trait.type) {
        case "draw":
        case "draw_cards":
        case "add":
        case "add_deck":
        case "add_extra_deck":
        case "add_hand_tag":
        case "add_deck_tag":
        case "add_extra_deck_tag":
        case "add_cost":
            _supported = true;
            break;
    }
    if (!_supported) return false;

    var _ok = trait_Execute(_trait, trait_CreateContext(effect_Source(SIDE_PLAYER, -1)));
    if (_ok) battle_ConsumeActionTrait(_trait_index);
    return _ok;
}

function battle_OnActionCardPlayed(_card) {
    battle_RefreshActionUses();
    action_card_used = false;
    battle_CancelTargeting();
    trait_ChainReset();

    var _traits = trait_GetFromCard(_card);
    for (var a = 0; a < array_length(_traits); a++) {
        if (!trait_ActionIsAuto(_traits[a])) continue;

        // an automatic effect (draw, add, ...) already happened: the card can no longer be taken back
        if (trait_IsRepeatable(_traits[a])) {
            if (battle_ExecuteActionTraitInstant(a)) action_card_used = true;
        } else {
            if (trait_ExecuteOnPlay(_traits[a], -1)) action_card_used = true;
        }
    }

    battle_TargetingContinueAfterAction(-1);
}

/// Move to the next action trait that can run (automatic ones run immediately).
/// A repeatable targeted trait with uses left asks for its next target first.
/// When nothing more can run, the action card is spent and leaves the action slot.
function battle_TargetingContinueAfterAction(_last_trait_index) {
    var _traits = battle_GetActionTraits();

    var _start = _last_trait_index + 1;
    if (_last_trait_index >= 0 && battle_CanUseActionTrait(_last_trait_index)) _start = _last_trait_index;

    for (var i = _start; i < array_length(_traits); i++) {
        if (!battle_CanUseActionTrait(i)) continue;

        var _trait = _traits[i];
        if (trait_ActionIsAuto(_trait)) {
            battle_ExecuteActionTraitInstant(i);
            continue;
        }

        if (!trait_ActionNeedsTargeting(_trait)) continue;
        if (trait_ActionNeedsOwnMonster(_trait) && unit_Count(SIDE_PLAYER) <= 0) continue;
        if (trait_GetActionPick(_trait) == "spot" && !battle_CanSummon(_trait)) continue;   // nowhere to summon
        if (trait_GetActionPick(_trait) == "any" && !battle_HasAnyBuffTarget()) continue;

        battle_BeginActionTargeting(i, _trait);
        return;
    }

    battle_CancelTargeting();
    trait_ChainFinish();
    battle_FinishActionCard();
}

function battle_HasAnyBuffTarget() {
    return array_length(targets_AnyUnit()) > 0;
}

/// Action cards whose traits need one of the player's monsters (attacker / heal / buff target)
function battle_ActionCardRequiresMonster(_card) {
    if (_card == undefined || _card.type != "action") return false;

    var _traits = trait_GetFromCard(_card);
    for (var i = 0; i < array_length(_traits); i++) {
        var _pick = trait_GetActionPick(_traits[i]);
        if (_pick == "attacker" || _pick == "ally" || _pick == "any") return true;
    }
    return false;
}

function battle_CanPlayActionCard(_card) {
    if (!battle_ActionCardRequiresMonster(_card)) return true;
    return unit_Count(SIDE_PLAYER) > 0;
}

/// Cancel an action card mid-play: it goes back to the hand,
/// unless some of its uses were already spent — then it is finished instead.
function battle_AbortActionCardPlay() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return false;

    if (action_card_used) {
        battle_FinishActionCard();
        trait_ChainFinish();
        return true;
    }

    var _removed = undefined;
    with (_board) {
        if (!action_slot.occupied || action_slot.card == undefined) return false;
        _removed = SCR_Board_RemoveCard(action_slot);
    }

    if (_removed == undefined) return false;

    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand != noone) {
        with (_hand) hand_AddCard(_removed);
    }

    // nothing was used: give back the resources and tribute cards it cost
    card_RefundPayment(action_payment);
    action_payment = undefined;
    battle_EnemyLog_Write(_removed.name + " returned to hand (cost refunded).");

    action_trait_uses = [];
    trait_ChainFinish();
    return true;
}

function battle_CancelCurrentAction() {
    var _source = pending_trait_source;

    battle_CancelTargeting();

    if (_source == "action") {
        battle_AbortActionCardPlay();
        return;
    }

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.is_dragging) {
        with (_board) SCR_DragDrop_Cancel();
    }

    trait_ChainFinish();
}

/// The action card is done: remove it from the action slot
function battle_FinishActionCard() {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board != noone && _board.action_slot.occupied) {
        with (_board) SCR_Board_RemoveCard(action_slot);
    }

    action_trait_uses = [];
    action_card_used = false;
    action_payment = undefined;
}
