/// @desc add_deck — add card id or random pick from id pool to player deck (uses SCR_Trait_AddDeck)

function monsterAbility_AddDeck_Activate(_slot_index, _monster, _trait) {
    var _pool = monsterAbility_GetCardIdPool(_trait);
    var _times = max(1, _trait.amount);
    var _added = false;

    for (var i = 0; i < _times; i++) {
        var _id = monsterAbility_PickCardIdFromPool(_trait, _pool);
        if (_id <= 0) continue;
        if (trait_ExecuteAddDeck(trait_CreateAddDeckContext(_id))) _added = true;
    }

    if (_added) monsterAbility_LogActivated(_monster, _trait);
    return _added;
}
