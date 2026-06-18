/// @desc Draw cards from deck into hand

function trait_ExecuteDraw(_ctx) {
    if (_ctx.amount <= 0) return false;

    var _drawn = 0;
    for (var i = 0; i < _ctx.amount; i++) {
        if (SCR_Hand_DrawFromDeck()) _drawn++;
        else break;
    }

    show_debug_message("Drew " + string(_drawn) + " card(s)");
    return _drawn > 0;
}

function trait_CreateDrawContext(_amount) {
    return {
        trait_type: "draw_cards",
        amount: _amount
    };
}
