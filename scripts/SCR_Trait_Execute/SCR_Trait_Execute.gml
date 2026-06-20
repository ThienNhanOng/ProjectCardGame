/// @desc Dispatch normalized traits to shared effect handlers



function trait_Execute(_trait, _ctx) {

    if (_trait == undefined) return false;



    switch (_trait.type) {

        case "attack":

            _ctx.amount = _trait.amount;

            return trait_ExecuteAttack(_ctx);



        case "heal":

            _ctx.amount = _trait.amount;

            return trait_ExecuteHeal(_ctx);



        case "self_buff":

        case "buff":

            _ctx.amount = _trait.amount;

            return trait_ExecuteBuffAttack(_ctx);



        case "draw":

        case "draw_cards":

            _ctx.amount = (_trait.amount > 0) ? _trait.amount : 1;

            return trait_ExecuteDraw(_ctx);



        case "attack_all":

            _ctx.amount = _trait.amount;

            return trait_ExecuteAttackAll(_ctx);



        case "heal_all":

            _ctx.amount = _trait.amount;

            return trait_ExecuteHealAll(_ctx);



        case "destroy":

            if (_ctx.amount <= 0) _ctx.amount = _trait.amount;

            return trait_ExecuteDestroy(_ctx);



        case "add":

            _ctx.card_id = _trait.card_id;

            return trait_ExecuteAddHand(_ctx);



        case "add_deck":

            _ctx.card_id = _trait.card_id;

            return trait_ExecuteAddDeck(_ctx);



        case "add_extra_deck":

            _ctx.card_id = _trait.card_id;

            return trait_ExecuteAddExtraDeck(_ctx);



        case "silence":

            if (_ctx.amount <= 0) _ctx.amount = max(1, _trait.amount);

            return trait_ExecuteSilence(_ctx);



        default:

            show_debug_message("Trait not implemented yet: " + string(_trait.type));

            return false;

    }

}



function trait_ExecuteByType(_traits, _type, _ctx) {

    var _trait = trait_FindFirst(_traits, _type);

    if (_trait == undefined) return false;

    return trait_Execute(_trait, _ctx);

}

