function SCR_Hand_GetSprite(_card) {
    var _spr = SPR_Monsterplaceholder;
    switch (_card.type) {
        case "monster":
        case "special_monster":
            _spr = SPR_Monsterplaceholder;
            break;
        case "weapon":
            _spr = SPR_Weaponplaceholder;
            break;
        case "action":
            _spr = SPR_Actionplaceholder;
            break;
    }
    return _spr;
}