/// @desc Dispatch monster traits to per-ability handlers during enemy turn

function monsterAbility_ActivateTrait(_slot_index, _monster, _trait) {
    if (_trait == undefined || _monster == undefined) return false;
    if (status_IsSilenced(_monster)) return false;

    if (monsterAbility_TraitRelay_IsSharedType(_trait.type)) {
        return monsterAbility_TraitRelay_Activate(_slot_index, _monster, _trait);
    }

    switch (_trait.type) {
        case "attack_all":
            return monsterAbility_AttackAll_Activate(_slot_index, _monster, _trait);
        case "self_buff":
            return monsterAbility_SelfBuff_Activate(_slot_index, _monster, _trait);
        case "buff":
            return monsterAbility_Buff_Activate(_slot_index, _monster, _trait);
        case "discard_hand":
            return monsterAbility_DiscardHand_Activate(_slot_index, _monster, _trait);
        case "discard_extra_deck":
            return monsterAbility_DiscardExtraDeck_Activate(_slot_index, _monster, _trait);
        case "add_deck":
            return monsterAbility_AddDeck_Activate(_slot_index, _monster, _trait);
        case "summon_enemy":
            return monsterAbility_SummonEnemy_Activate(_slot_index, _monster, _trait);
        default:
            if (monsterAbility_GetDelay(_trait) > 0) {
                monsterAbility_ApplyDelayedEffect(_slot_index, _monster, _trait);
                monsterAbility_LogActivated(_monster, _trait);
                return true;
            }
return false;
    }
}

function monsterAbility_ApplyDelayedEffect(_slot_index, _monster, _trait) {
    if (monsterAbility_TraitRelay_IsSharedType(_trait.type)) {
        monsterAbility_TraitRelay_Activate(_slot_index, _monster, _trait);
        return;
    }

    switch (_trait.type) {
        case "attack_all":
            monsterAbility_attack_all(_slot_index, _monster, max(1, _trait.amount));
            break;
        case "self_buff":
            monsterAbility_self_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
            break;
        case "buff":
            monsterAbility_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
            break;
        case "discard_hand":
            monsterAbility_DiscardHand_Activate(_slot_index, _monster, _trait);
            break;
        case "discard_extra_deck":
            monsterAbility_DiscardExtraDeck_Activate(_slot_index, _monster, _trait);
            break;
        case "add_deck":
            monsterAbility_AddDeck_Activate(_slot_index, _monster, _trait);
            break;
        case "summon_enemy":
            monsterAbility_SummonEnemy_Activate(_slot_index, _monster, _trait);
            break;
        default:
break;
    }
}

function monsterAbility_TryActivateStep(_slot_index, _monster) {
    monsterAbility_InitState(_monster);
    if (status_IsSilenced(_monster)) return;

    if (_monster.pending_delayed != undefined) {
        if (_monster.pending_delayed.countdown <= 0) {
            var _pending_trait = _monster.pending_delayed.trait;
            _monster.pending_delayed = undefined;
            monsterAbility_ActivateTrait(_slot_index, _monster, _pending_trait);
            if (!monsterAbility_Picker_IsActive()) {
                monsterAbility_TryRestartDelayed(_slot_index, _monster, _pending_trait);
            }
        }
        return;
    }

    var _trait = monsterAbility_GetCurrentTrait(_monster);
    if (_trait == undefined || monsterAbility_IsPassiveType(_trait.type)) return;

    if (monsterAbility_GetDelay(_trait) > 0) {
        monsterAbility_StartDelayed(_slot_index, _monster, _trait);
        return;
    }

    monsterAbility_ActivateTrait(_slot_index, _monster, _trait);
}
