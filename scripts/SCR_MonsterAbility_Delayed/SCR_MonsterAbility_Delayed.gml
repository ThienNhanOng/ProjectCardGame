/// @desc Delayed monster ability countdown and logging

function monsterAbility_LogCountdown(_slot_index, _monster) {
    if (_monster.pending_delayed == undefined) return;
    var _countdown = _monster.pending_delayed.countdown;
    if (_countdown <= 0) return;

    var _name = _monster.pending_delayed.display_name;
    var _turn_word = (_countdown == 1) ? "turn" : "turns";
    battle_EnemyLog_Action(_monster.name + ": " + string(_countdown)
        + " enemy " + _turn_word + " remaining until " + _name + " activates.");
}

function monsterAbility_StartDelayed(_slot_index, _monster, _trait) {
    var _delay = monsterAbility_GetDelay(_trait);
    if (_delay <= 0) return false;

    _monster.pending_delayed = {
        trait: _trait,
        countdown: _delay,
        display_name: monsterAbility_GetDisplayName(_trait)
    };
    return true;
}

function monsterAbility_TickDelayedCountdown(_monster) {
    if (_monster == undefined || _monster.pending_delayed == undefined) return;
    if (_monster.pending_delayed.countdown > 0) {
        _monster.pending_delayed.countdown--;
    }
}

function monsterAbility_ShouldRepeatDelayed(_trait) {
    if (_trait == undefined) return false;
    if (monsterAbility_GetDelay(_trait) <= 0) return false;
    return _trait.type == "discard_hand" || _trait.type == "discard_extra_deck";
}

function monsterAbility_TryRestartDelayed(_slot_index, _monster, _trait) {
    if (_monster == undefined || _trait == undefined || !_monster.alive) return;
    if (!monsterAbility_ShouldRepeatDelayed(_trait)) return;
    if (_monster.pending_delayed != undefined) return;
    if (status_IsSilenced(_monster)) return;
    monsterAbility_StartDelayed(_slot_index, _monster, _trait);
}
