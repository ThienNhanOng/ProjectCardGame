/// @desc Draw cards from deck into hand

function trait_IsDrawType(_type) {
    return _type == "draw" || _type == "draw_cards";
}

function trait_ExecuteDraw(_ctx) {
    var _amount = _ctx.amount;
    if (_amount <= 0) _amount = 1;

    var _drawn = 0;
    for (var i = 0; i < _amount; i++) {
        if (SCR_Hand_DrawFromDeck()) _drawn++;
        else break;
    }

    show_debug_message("Drew " + string(_drawn) + " card(s) from deck");
    return _drawn > 0;
}

function trait_CreateDrawContext(_amount) {
    return {
        trait_type: "draw_cards",
        amount: _amount
    };
}
