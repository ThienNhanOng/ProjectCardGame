var _deckbuilder = instance_find(OBJ_DeckBuilder, 0);
if (_deckbuilder != noone && !_deckbuilder.click_processed) {
    SCR_CardSlot_AddToDeck();
}
