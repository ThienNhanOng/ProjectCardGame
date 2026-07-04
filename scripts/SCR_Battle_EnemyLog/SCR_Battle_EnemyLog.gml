/// @desc Append-only enemy turn log (Output window + file + on-screen battle log)

#macro BATTLE_LOG_LINE_SEP -1

function battle_EnemyLog_Init() {
    global.enemy_log_path = working_directory + "enemy_battle_log.txt";
    global.battle_action_log = [];
    global.battle_action_log_scroll = 0;
    if (file_exists(global.enemy_log_path)) {
        file_delete(global.enemy_log_path);
    }
    battle_EnemyLog_Write("=== Enemy battle log ===");
    battle_EnemyLog_Write("Log file: " + global.enemy_log_path);
}

function battle_EnemyLog_EnsureGlobals() {
    if (!variable_global_exists("enemy_log_path")) {
        global.enemy_log_path = working_directory + "enemy_battle_log.txt";
    }
    if (!variable_global_exists("battle_action_log") || !is_array(global.battle_action_log)) {
        global.battle_action_log = [];
    }
    if (!variable_global_exists("battle_action_log_scroll")) {
        global.battle_action_log_scroll = 0;
    }
}

function battle_EnemyLog_GetPanelLayout() {
    return {
        x: 663,
        y: 50,
        w: 290,
        h: 210
    };
}

function battle_EnemyLog_MeasureEntry(_text, _inner_w) {
    return string_height_ext(_text, BATTLE_LOG_LINE_SEP, _inner_w);
}

function battle_EnemyLog_GetContentMetrics(_panel = undefined) {
    if (_panel == undefined) _panel = battle_EnemyLog_GetPanelLayout();

    var _pad = 10;
    var _scroll_gutter = 14;
    var _header_h = 22;
    var _inner_w = _panel.w - (_pad * 2) - _scroll_gutter;
    var _content_y = _panel.y + _pad + _header_h;
    var _content_h = (_panel.y + _panel.h - _pad) - _content_y;

    var _heights = [];
    var _total_h = 0;
    var _entry_gap = 8;
    var _count = array_length(global.battle_action_log);

    for (var i = 0; i < _count; i++) {
        var _h = battle_EnemyLog_MeasureEntry(global.battle_action_log[i], _inner_w);
        array_push(_heights, _h);
        _total_h += _h;
        if (i < _count - 1) _total_h += _entry_gap;
    }

    return {
        pad: _pad,
        scroll_gutter: _scroll_gutter,
        header_h: _header_h,
        inner_w: _inner_w,
        entry_gap: _entry_gap,
        content_x: _panel.x + _pad,
        content_y: _content_y,
        content_h: _content_h,
        content_bottom: _content_y + _content_h,
        total_h: _total_h,
        heights: _heights,
        max_scroll: max(0, _total_h - _content_h)
    };
}

function battle_EnemyLog_IsMouseOverPanel() {
    var _panel = battle_EnemyLog_GetPanelLayout();
    return point_in_rectangle(mouse_x, mouse_y, _panel.x, _panel.y, _panel.x + _panel.w, _panel.y + _panel.h);
}

function battle_EnemyLog_IsAtBottom(_metrics) {
    return (global.battle_action_log_scroll >= _metrics.max_scroll - 1);
}

function battle_EnemyLog_Step() {
    battle_EnemyLog_EnsureGlobals();
    if (array_length(global.battle_action_log) <= 0) return;
    if (!battle_EnemyLog_IsMouseOverPanel()) return;

    var _metrics = battle_EnemyLog_GetContentMetrics();
    if (_metrics.max_scroll <= 0) {
        global.battle_action_log_scroll = 0;
        return;
    }

    var _step = 24;
    if (array_length(_metrics.heights) > 0) {
        _step = max(24, floor(_metrics.heights[array_length(_metrics.heights) - 1]));
    }
    var _delta = 0;

    if (mouse_wheel_up()) _delta -= _step;
    if (mouse_wheel_down()) _delta += _step;

    if (_delta != 0) {
        global.battle_action_log_scroll = clamp(global.battle_action_log_scroll + _delta, 0, _metrics.max_scroll);
    }
}

function battle_EnemyLog_PushAction(_line) {
    battle_EnemyLog_EnsureGlobals();

    var _metrics_before = battle_EnemyLog_GetContentMetrics();
    var _at_bottom = battle_EnemyLog_IsAtBottom(_metrics_before);

    array_push(global.battle_action_log, _line);
    while (array_length(global.battle_action_log) > MONSTER_ABILITY_LOG_MAX) {
        array_delete(global.battle_action_log, 0, 1);
    }

    var _metrics_after = battle_EnemyLog_GetContentMetrics();
    if (_at_bottom) {
        global.battle_action_log_scroll = _metrics_after.max_scroll;
    } else {
        global.battle_action_log_scroll = clamp(global.battle_action_log_scroll, 0, _metrics_after.max_scroll);
    }
}

function battle_EnemyLog_Write(_line) {
battle_EnemyLog_EnsureGlobals();

    var _file = file_text_open_append(global.enemy_log_path);
    file_text_write_string(_file, _line + "\r\n");
    file_text_close(_file);
}

function battle_EnemyLog_Action(_line) {
    battle_EnemyLog_PushAction(_line);
    battle_EnemyLog_Write(_line);
}

function battle_EnemyLog_GetTurn() {
    var _bm = instance_find(OBJ_BattleManager, 0);
    if (_bm == noone) return 0;
    with (_bm) return turn_number;
}

function battle_EnemyLog_DrawScrollBar(_panel, _metrics) {
    if (_metrics.max_scroll <= 0) return;

    var _track_x = _panel.x + _panel.w - _metrics.pad - 6;
    var _track_top = _metrics.content_y + 2;
    var _track_bottom = _metrics.content_bottom - 2;
    var _track_h = _track_bottom - _track_top;

    draw_set_color(make_color_rgb(55, 55, 62));
    draw_rectangle(_track_x, _track_top, _track_x + 4, _track_bottom, false);

    var _thumb_ratio = _metrics.content_h / max(_metrics.total_h, 1);
    var _thumb_h = max(16, floor(_track_h * _thumb_ratio));
    var _scroll_ratio = global.battle_action_log_scroll / _metrics.max_scroll;
    var _thumb_y = _track_top + floor((_track_h - _thumb_h) * (1 - _scroll_ratio));

    draw_set_color(make_color_rgb(170, 170, 180));
    draw_rectangle(_track_x, _thumb_y, _track_x + 4, _thumb_y + _thumb_h, false);
}

function battle_EnemyLog_DrawPanel() {
    battle_EnemyLog_EnsureGlobals();
    if (array_length(global.battle_action_log) <= 0) return;

    var _panel = battle_EnemyLog_GetPanelLayout();
    var _metrics = battle_EnemyLog_GetContentMetrics(_panel);
    global.battle_action_log_scroll = clamp(global.battle_action_log_scroll, 0, _metrics.max_scroll);

    if (battle_EnemyLog_IsAtBottom(_metrics)) {
        global.battle_action_log_scroll = _metrics.max_scroll;
    }

    draw_set_alpha(0.72);
    draw_set_color(make_color_rgb(28, 28, 32));
    draw_rectangle(_panel.x, _panel.y, _panel.x + _panel.w, _panel.y + _panel.h, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(150, 150, 160));
    draw_rectangle(_panel.x, _panel.y, _panel.x + _panel.w, _panel.y + _panel.h, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _title = "Battle log";
    if (_metrics.max_scroll > 0) {
        _title += " (scroll)";
    }
    draw_set_color(c_yellow);
    draw_text(_panel.x + _metrics.pad, _panel.y + _metrics.pad, _title);

    var _prev_scissor = gpu_get_scissor();
    gpu_set_scissor(
        floor(_metrics.content_x),
        floor(_metrics.content_y),
        floor(_metrics.inner_w + _metrics.scroll_gutter),
        floor(_metrics.content_h + 2)
    );

    var _cy = _metrics.content_y - global.battle_action_log_scroll;
    var _count = array_length(global.battle_action_log);

    draw_set_color(c_ltgray);
    for (var i = 0; i < _count; i++) {
        var _text = global.battle_action_log[i];
        var _entry_h = _metrics.heights[i];

        if (_cy + _entry_h >= _metrics.content_y && _cy <= _metrics.content_bottom) {
            draw_text_ext(_metrics.content_x, _cy, _text, BATTLE_LOG_LINE_SEP, _metrics.inner_w);
        }

        _cy += _entry_h + _metrics.entry_gap;
    }

    gpu_set_scissor(_prev_scissor);
    battle_EnemyLog_DrawScrollBar(_panel, _metrics);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

function battle_EnemyLog_MonsterLabel(_slot_index) {
    var _board = instance_find(OBJ_BoardManager, 0);
    if (_board == noone) return "slot " + string(_slot_index);

    var _slot = _board.enemy_slots[_slot_index];
    if (!_slot.occupied || _slot.card == undefined) {
        return "slot " + string(_slot_index);
    }
    return _slot.card.name + " (slot " + string(_slot_index) + ")";
}

function battle_EnemyLog_Attack(_source_slot, _source, _player_slot, _damage) {
    battle_EnemyLog_Action(_source.name + " attacks for " + string(_damage) + " damage.");
}

function battle_EnemyLog_Heal(_source_slot, _source, _target_slot, _amount, _before, _after, _max) {
    battle_EnemyLog_Action(_source.name + " activated heal.");
}

function battle_EnemyLog_BuffAttack(_source_slot, _source, _target_slot, _amount, _before, _after) {
    battle_EnemyLog_Action(_source.name + " activated self buff.");
}

function battle_EnemyLog_Skipped(_source_slot, _source, _reason) {
    battle_EnemyLog_Action(_source.name + " skipped: " + _reason + ".");
}
