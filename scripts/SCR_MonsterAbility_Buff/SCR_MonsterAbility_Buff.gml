/// @desc buff(amount, turns) — buff lowest-ATK allied enemy immediately

function monsterAbility_buff(_slot_index, _monster, _amount, _turns) {
    if (_amount <= 0) return false;

    var _ally = battle_EnemyPickBuffAllyTarget(_slot_index);
    if (_ally < 0) return false;
    if (!battle_BuffEnemyMonster(_ally, _amount)) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return true;
    var _target_card = _board.enemy_slots[_ally].card;
    monsterAbility_ApplyTimedBuff(_target_card, _amount, _turns, _monster.name);
    return true;
}

function monsterAbility_Buff_Activate(_slot_index, _monster, _trait) {
    var _ok = monsterAbility_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
    if (_ok) monsterAbility_LogActivated(_monster, _trait);
    return _ok;
}
