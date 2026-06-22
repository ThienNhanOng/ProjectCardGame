/// @desc Add a card by database id directly to hand

function trait_ExecuteAddHand(_ctx) {
    if (_ctx.card_id <= 0) return false;

    var _hand = instance_find(OBJ_Hand, 0);
    var _deck = instance_find(OBJ_Deck, 0);
    if (_hand == noone || _deck == noone) return false;

    var _card = undefined;
    with (_deck) {
        _card = deck_CreateRuntimeCard(_ctx.card_id);
    }
    if (_card == undefined) {
        show_debug_message("Add to hand failed: card id " + string(_ctx.card_id) + " not found");
        return false;
    }

    var _added = false;
    with (_hand) {
        if (hand_IsFull()) {
            show_debug_message("Hand full — cannot add card id " + string(_ctx.card_id));
            return false;
        }
        _added = hand_AddCard(_card);
    }

    if (_added) {
        show_debug_message("Added " + _card.name + " (id " + string(_ctx.card_id) + ") to hand");
        var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) trait_ChainRegisterAddedCard(_card);
        }
    }
    return _added;
}

function trait_CreateAddHandContext(_card_id) {
    return {
        trait_type: "add",
        card_id: _card_id,
        amount: 1
    };
}
