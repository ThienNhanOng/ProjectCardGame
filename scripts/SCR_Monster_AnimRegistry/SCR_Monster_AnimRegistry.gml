/// @desc Route draw/update to per-monster animation scripts

function monsterAnim_GetKey(_monster) {
    return _monster.collection + ":" + string(_monster.id);
}

function monsterAnim_Draw(_slot, _monster, _layout) {
    switch (monsterAnim_GetKey(_monster)) {
        case "enemyGoblins_01:1": monsterAnim_GoblinSoldier_Draw(_slot, _monster, _layout); break;
        case "enemyGoblins_01:2": monsterAnim_GoblinMage_Draw(_slot, _monster, _layout); break;
        case "enemyGoblins_01:3": monsterAnim_GoblinCommander_Draw(_slot, _monster, _layout); break;
        case "enemyOrcs_01:1": monsterAnim_OrcBrute_Draw(_slot, _monster, _layout); break;
        case "enemyOrcs_01:2": monsterAnim_OrcShaman_Draw(_slot, _monster, _layout); break;
        default: monsterAnim_Default_Draw(_slot, _monster, _layout); break;
    }
}

function monsterAnim_Update(_monster) {
    switch (monsterAnim_GetKey(_monster)) {
        case "enemyGoblins_01:1": monsterAnim_GoblinSoldier_Update(_monster); break;
        case "enemyGoblins_01:2": monsterAnim_GoblinMage_Update(_monster); break;
        case "enemyGoblins_01:3": monsterAnim_GoblinCommander_Update(_monster); break;
        case "enemyOrcs_01:1": monsterAnim_OrcBrute_Update(_monster); break;
        case "enemyOrcs_01:2": monsterAnim_OrcShaman_Update(_monster); break;
        default: monsterAnim_Default_Update(_monster); break;
    }
}
