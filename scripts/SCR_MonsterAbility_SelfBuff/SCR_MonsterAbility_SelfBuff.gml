/// @desc self_buff(amount, turns) — buff caster immediately for enemy turns

function monsterAbility_self_buff(_slot_index, _monster, _amount, _turns) {
    if (_amount <= 0) return false;

    if (!battle_BuffEnemyMonster(_slot_index, _amount)) return false;

    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return true;
    var _target_card = _board.enemy_slots[_slot_index].card;
    monsterAbility_ApplyTimedBuff(_target_card, _amount, _turns);
    return true;
}

function monsterAbility_SelfBuff_Activate(_slot_index, _monster, _trait) {
    var _ok = monsterAbility_self_buff(_slot_index, _monster, _trait.amount, monsterAbility_GetBuffTurns(_trait));
    if (_ok) monsterAbility_LogActivated(_monster, _trait);
    return _ok;
}
