/// @desc Route shared player trait effects for enemy monsters (no duplicate logic)

function monsterAbility_TraitRelay_Activate(_slot_index, _monster, _trait) {
    if (_trait == undefined || _monster == undefined) return false;

    switch (_trait.type) {
        case "heal":
            var _heal_target = battle_EnemyPickHealTarget(_slot_index);
            var _heal_ok = trait_Execute(_trait, trait_CreateHealContext(_trait.amount, "enemy", _heal_target));
            if (_heal_ok) monsterAbility_LogActivated(_monster, _trait);
            return _heal_ok;

        case "heal_all":
            var _heal_all_ok = trait_Execute(_trait, trait_CreateHealAllContext(_trait.amount, "enemy"));
            if (_heal_all_ok) monsterAbility_LogActivated(_monster, _trait);
            return _heal_all_ok;

        case "silence":
        case "shroud":
            var _shroud_target = battle_PickRandomPlayerMonsterSlot();
            if (_shroud_target < 0) return false;
            var _shroud_ok = trait_ExecuteShroud(
                trait_CreateShroudContext(max(1, _trait.amount), _shroud_target));
            if (_shroud_ok) monsterAbility_LogActivated(_monster, _trait);
            return _shroud_ok;

        case "destroy":
            var _destroyed = 0;
            var _count = max(1, _trait.amount);
            for (var n = 0; n < _count; n++) {
                if (battle_IsPlayerDefeated()) break;
                var _target = battle_PickRandomPlayerMonsterSlot();
                if (_target < 0) break;
                if (trait_Execute(_trait, trait_CreateDestroyContext(1, "player", _target))) {
                    _destroyed++;
                }
            }
            if (_destroyed > 0) monsterAbility_LogActivated(_monster, _trait);
            return _destroyed > 0;

        default:
            return false;
    }
}

function monsterAbility_TraitRelay_IsSharedType(_type) {
    return _type == "heal" || _type == "heal_all" || _type == "silence" || _type == "shroud" || _type == "destroy";
}
