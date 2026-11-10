/// @desc Run a normalized trait (JSON ability) through the universal card effects.
///
/// One dispatcher for every source — player monsters, spirits, weapons, action cards and enemy monsters.
/// A trait has an EFFECT and a TARGET rule (see scr_trait_parse). The context says who acts and,
/// for single-target rules, which target the player clicked or the enemy AI chose:
///
///     var _ctx = trait_CreateContext(effect_Source(SIDE_ENEMY, _slot), targets_Single(SIDE_ENEMY, _ally));
///     trait_Execute(_trait, _ctx);
///
/// Rules that need no choice (self, all_allies, all_enemies) are resolved here automatically.

function trait_CreateContext(_source, _targets = []) {
    return { source: _source, targets: _targets };
}

/// Units a trait affects: the chosen targets, or the ones its target rule implies
function trait_ResolveTargets(_trait, _ctx) {
    if (array_length(_ctx.targets) > 0) return _ctx.targets;

    var _src = _ctx.source;
    switch (_trait.target) {
        case "self": return (_src.slot >= 0) ? targets_Single(_src.side, _src.slot) : [];
        case "all_allies": return targets_AllAllies(_src);
        case "all_enemies": return targets_AllOpponents(_src);
    }
    return [];
}

function trait_Execute(_trait, _ctx) {
    if (_trait == undefined) return false;

    var _src = _ctx.source;
    var _amount = _trait.amount;

    switch (_trait.effect) {
        // ---- unit effects (same code for player and enemy sources) ----
        case "attack":
            if (_trait.target == "all_enemies") return card_Damage(_src, targets_AllOpponents(_src), _amount);
            var _defenders = [];
            for (var i = 0; i < array_length(_ctx.targets); i++) {
                var _t = _ctx.targets[i];
                array_push(_defenders, targets_AttackDefender(_t.side, _t.slot)[0]);
            }
            return card_Damage(_src, _defenders, _amount);

        case "damage":
            return card_Damage(_src, trait_ResolveTargets(_trait, _ctx), _amount);

        case "heal":
            return card_Heal(_src, trait_ResolveTargets(_trait, _ctx), _amount);

        case "buff":
            return card_BuffAttack(_src, trait_ResolveTargets(_trait, _ctx), _amount);

        case "destroy":
            return card_Destroy(_src, trait_ResolveTargets(_trait, _ctx));

        case "silence":
            return card_Silence(_src, trait_ResolveTargets(_trait, _ctx), max(1, _amount));

        case "shroud":
            return card_Shroud(_src, trait_ResolveTargets(_trait, _ctx), max(1, _amount));

        // ---- cards ----
        case "add_card":
            return card_AddCard(_src, trait_GetAddCardZone(_trait.type), _trait.card_id);

        case "search_card":
            if (_trait.type == "add_hand_with_cost" && _trait.apply_cost <= 0) return false;
            return deck_TagPicker_Begin(_trait);

        case "summon":   // the chosen target is the free spot the player picked
            if (array_length(_ctx.targets) <= 0) return false;
            return card_SummonToSpot(_src, _ctx.targets[0].slot, _trait.card_id);
    }

    switch (_trait.type) {
        case "draw":
        case "draw_cards":
            return card_DrawCards(_src, max(1, _amount));

        // ---- source board position / resources (scr_card_resources) ----
        case "openzone":
            return card_OpenZones(_src, _amount);

        case "add_counter":
            return card_AddResourceCounter(_src, _amount);

        case "remove_counter":
            return card_RemoveResourceCounter(_src, _amount);

        case "no_board_expire":
            return card_SetNoBoardExpire(_src);

        case "add_board_turns":
            return card_AddBoardTurns(_src, _amount);

        case "add_cost":
            return trait_ExecuteAddCostToChain(_trait);
    }
    return false;
}

/// Non-unit traits that run by themselves when a card is played
function trait_IsAutoCardEffect(_type) {
    switch (_type) {
        case "draw":
        case "draw_cards":
        case "add":
        case "add_deck":
        case "add_extra_deck":
        case "add_hand_tag":
        case "add_hand_with_cost":
        case "add_deck_tag":
        case "add_extra_deck_tag":
        case "openzone":
        case "add_counter":
        case "remove_counter":
        case "no_board_expire":
        case "add_board_turns":
        case "add_cost":
            return true;
    }
    return false;
}

/// Traits that fire by themselves when a player monster / spirit / weapon is played.
/// Traits that need a target return false here and are handled by player targeting instead.
function trait_ExecuteOnPlay(_trait, _player_slot) {
    if (_trait == undefined) return false;
    if (!trait_IsAutoUnitEffect(_trait) && !trait_IsAutoCardEffect(_trait.type)) return false;
    return trait_Execute(_trait, trait_CreateContext(effect_Source(SIDE_PLAYER, _player_slot)));
}
