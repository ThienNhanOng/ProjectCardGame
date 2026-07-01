/// @desc discard_extra_deck — player chooses spirit card(s) to discard from extra deck

function monsterAbility_DiscardExtraDeck_Activate(_slot_index, _monster, _trait) {
    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone || _deck.extra_deck_Count <= 0) return false;

    var _count = min(max(1, _trait.amount), _deck.extra_deck_Count);
    var _prompt = _monster.name + " — choose " + string(_count) + " extra deck card(s) to discard";

    monsterAbility_LogActivated(_monster, _trait);

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) monsterAbility_Picker_Begin("discard_extra_deck", _count, _prompt, "", _slot_index, _trait);
    return true;
}
