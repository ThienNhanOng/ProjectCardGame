function SCR_CardSlot_CheckVisibility() {
    var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);

    if (_deckbuilder == noone) {
        return false;
    }

    var _container_top = _deckbuilder.container_y;
    var _container_bottom = _deckbuilder.container_y + _deckbuilder.container_h;

    if (y + card_h < _container_top || y > _container_bottom) {
        return false;
    }

    return true;
}