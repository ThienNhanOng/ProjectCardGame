/// @desc summon_enemy — queue allied monster at front after delay (summoner)

function monsterAbility_SummonEnemy_Activate(_slot_index, _monster, _trait) {
    var _entry = monsterAbility_BuildQueueEntry(_monster, _trait);
    if (_entry == undefined) return false;

    if (!monster_QueueInsertFront(_entry)) return false;

    monsterAbility_LogActivated(_monster, _trait);
    return true;
}
