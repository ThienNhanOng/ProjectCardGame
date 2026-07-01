/// @desc Enemy turn attack step — single target or active attack_all charges

function monsterAbility_PerformAttack(_slot_index, _monster) {
    if (_monster == undefined || !_monster.alive || battle_IsPlayerDefeated()) return false;

    monsterAbility_InitState(_monster);
    var _damage = max(0, _monster.attack);

    if (_monster.attack_all_charges > 0) {
        return monsterAbility_AttackAll_Perform(_slot_index, _monster, _damage);
    }

    var _player_target = battle_PickRandomPlayerMonsterSlot();
    var _ctx = trait_CreateAttackContext(_damage, "player", _player_target);
    var _ok = trait_ExecuteAttack(_ctx);
    if (_ok) {
        battle_EnemyLog_Action(_monster.name + " attacks for " + string(_damage) + " damage.");
    }
    return _ok;
}
