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
