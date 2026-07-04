/// @desc Battle resource pool (displayed as "Resources" on the HUD)

function battle_InitResourceSlotTracking() {
    player_resources_base_max = 10;
    resource_add_buff_by_slot = [0, 0, 0, 0, 0];
    resource_add_buff_orphan = 0;
    resource_max_reduce_by_slot = [0, 0, 0, 0, 0];
}

function battle_InitResources() {
    battle_InitResourceSlotTracking();
    battle_RecalculateResourceMax();
    player_resources = player_resources_max;
}

function battle_RecalculateResourceMax() {
    var _max = player_resources_base_max;
    for (var i = 0; i < array_length(resource_max_reduce_by_slot); i++) {
        _max -= resource_max_reduce_by_slot[i];
    }
    player_resources_max = max(0, _max);
}

function battle_GetResourceAddBuffTotal() {
    var _total = resource_add_buff_orphan;
    for (var i = 0; i < array_length(resource_add_buff_by_slot); i++) {
        _total += resource_add_buff_by_slot[i];
    }
    return _total;
}

function battle_GetResources() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return 0;
    with (_bm) return player_resources;
}

function battle_GetResourcesMax() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return 0;
    with (_bm) return player_resources_max;
}

function battle_CanAffordResources(_amount) {
    if (_amount <= 0) return true;
    return battle_GetResources() >= _amount;
}

function battle_SpendResources(_amount) {
    if (_amount <= 0) return true;
    if (!battle_CanAffordResources(_amount)) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;

    with (_bm) {
        player_resources = max(0, player_resources - _amount);
}
    return true;
}

/// @desc add_counter — temporary current boost for this turn (no upper cap; e.g. 16/10)
function battle_AddResourcesTemporary(_amount, _player_slot = -1) {
    if (_amount <= 0) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;

    with (_bm) {
        player_resources += _amount;

        if (_player_slot >= 0 && _player_slot < array_length(resource_add_buff_by_slot)) {
            resource_add_buff_by_slot[_player_slot] += _amount;
        } else {
            resource_add_buff_orphan += _amount;
        }

}
    return true;
}

/// @desc remove_counter — reduce max while the source monster stays on board
function battle_RemoveResourcesMaxFromSlot(_amount, _player_slot = -1) {
    if (_amount <= 0) return false;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return false;

    with (_bm) {
        if (_player_slot >= 0 && _player_slot < array_length(resource_max_reduce_by_slot)) {
            resource_max_reduce_by_slot[_player_slot] += _amount;
        } else {
            player_resources_base_max = max(0, player_resources_base_max - _amount);
        }

        battle_RecalculateResourceMax();

}
    return true;
}

/// @desc Remove add/remove counter effects tied to a destroyed monster slot
function battle_ClearResourceEffectsFromSlot(_player_slot) {
    if (_player_slot < 0) return;

    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        if (_player_slot >= array_length(resource_add_buff_by_slot)) return;

        var _add_buff = resource_add_buff_by_slot[_player_slot];
        var _max_reduce = resource_max_reduce_by_slot[_player_slot];

        if (_add_buff <= 0 && _max_reduce <= 0) return;

        if (_add_buff > 0) {
            player_resources = max(0, player_resources - _add_buff);
            resource_add_buff_by_slot[_player_slot] = 0;
        }

        if (_max_reduce > 0) {
            resource_max_reduce_by_slot[_player_slot] = 0;
            battle_RecalculateResourceMax();
        }

}
}

/// @desc Strip temporary add_counter buffs at end of player turn
function battle_ClearTurnResourceAddBuffs() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        var _buff_total = battle_GetResourceAddBuffTotal();
        if (_buff_total <= 0) return;

        player_resources = max(0, player_resources - _buff_total);
        resource_add_buff_orphan = 0;
        for (var i = 0; i < array_length(resource_add_buff_by_slot); i++) {
            resource_add_buff_by_slot[i] = 0;
        }

}
}

/// @desc Refill current resources to max at the start of each player turn
function battle_RefreshResourcesForTurn() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return;

    with (_bm) {
        resource_add_buff_orphan = 0;
        for (var i = 0; i < array_length(resource_add_buff_by_slot); i++) {
            resource_add_buff_by_slot[i] = 0;
        }
        player_resources = player_resources_max;
}
}

function battle_GetResourcesDisplayRect() {
    var _layout = battle_GetPreviewPanelLayout();
    return {
        left: _layout.x,
        top: 8,
        right: _layout.x + _layout.w,
        bottom: 52
    };
}

function battle_DrawResourcesCounter() {
    var _rect = battle_GetResourcesDisplayRect();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_red);
    draw_text(_rect.left, _rect.top, "Resources");

    draw_set_halign(fa_right);
    draw_set_valign(fa_middle);
    draw_text(_rect.right, (_rect.top + _rect.bottom) / 2,
        string(player_resources) + "/" + string(player_resources_max));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
