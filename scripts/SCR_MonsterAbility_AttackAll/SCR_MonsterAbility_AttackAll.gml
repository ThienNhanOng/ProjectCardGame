/// @desc attack_all(N) — normal attack on activation; next N attacks hit all player monsters

function monsterAbility_attack_all(_slot_index, _monster, _attack_count) {
    monsterAbility_InitState(_monster);
    _monster.attack_all_charges = max(0, floor(_attack_count));
}

function monsterAbility_AttackAll_Activate(_slot_index, _monster, _trait) {
    monsterAbility_attack_all(_slot_index, _monster, max(1, _trait.amount));
    monsterAbility_LogActivated(_monster, _trait);
    return true;
}

function monsterAbility_AttackAll_Perform(_slot_index, _monster, _damage) {
    var _ok = trait_ExecuteAttackAll(trait_CreateAttackAllContext(_damage, "player"));
    if (_ok) {
        battle_EnemyLog_Action(_monster.name + " attacks all for " + string(_damage) + " damage.");
        _monster.attack_all_charges--;
    }
    return _ok;
}
