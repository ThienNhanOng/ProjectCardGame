/// @desc Add a card by database id to the battle deck or extra (spirit) deck

function trait_ExecuteAddDeck(_ctx) {
    if (_ctx.card_id <= 0) return false;

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;

    var _added = false;
    with (_deck) {
        _added = deck_AddCard(_ctx.card_id);
    }

    if (_added) {
var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) trait_ChainRegisterAddedDeckId(_ctx.card_id);
        }
    }
    return _added;
}

function trait_ExecuteAddExtraDeck(_ctx) {
    if (_ctx.card_id <= 0) return false;

    var _deck = instance_find(OBJ_Deck, 0);
    if (_deck == noone) return false;

    var _added = false;
    with (_deck) {
        _added = deck_AddExtraCard(_ctx.card_id);
    }

    if (_added) {
var _bm = instance_find(OBJ_BattleManager, 0);
        if (_bm != noone) {
            with (_bm) trait_ChainRegisterAddedDeckId(_ctx.card_id);
        }
    }
    return _added;
}

function trait_CreateAddDeckContext(_card_id) {
    return {
        trait_type: "add_deck",
        card_id: _card_id,
        amount: 1
    };
}

function trait_CreateAddExtraDeckContext(_card_id) {
    return {
        trait_type: "add_extra_deck",
        card_id: _card_id,
        amount: 1
    };
}
