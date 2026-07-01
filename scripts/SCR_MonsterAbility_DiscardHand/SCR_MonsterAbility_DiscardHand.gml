/// @desc discard_hand — player chooses card(s) to discard from hand

function monsterAbility_DiscardHand_Activate(_slot_index, _monster, _trait) {
    var _hand = instance_find(OBJ_Hand, 0);
    if (_hand == noone || _hand.hand_Count <= 0) return false;

    var _count = min(max(1, _trait.amount), _hand.hand_Count);
    var _filter = variable_struct_exists(_trait, "hand_filter") ? _trait.hand_filter : "";
    var _prompt = _monster.name + " — choose " + string(_count) + " card(s) to discard";

    monsterAbility_LogActivated(_monster, _trait);

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;
    with (_bm) monsterAbility_Picker_Begin("discard_hand", _count, _prompt, _filter, _slot_index, _trait);
    return true;
}
