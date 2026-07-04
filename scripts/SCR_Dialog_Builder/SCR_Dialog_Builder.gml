/// @desc Helpers for building dialog scripts returned to dialog_Start()

function dialog_Left(_sprite_or_object = undefined, _speaker_key = "", _visible = true) {
    var _spr = (_sprite_or_object == undefined)
        ? dialog_DefaultLeftSprite()
        : dialog_ResolveSprite(_sprite_or_object);
    return {
        kind: "left",
        sprite: dialog_ValidatePortraitSprite(_spr, true),
        speaker_key: string_lower(string(_speaker_key)),
        visible: _visible
    };
}

function dialog_Right(_sprite_or_object = undefined, _speaker_key = "", _visible = true) {
    var _spr = (_sprite_or_object == undefined)
        ? dialog_DefaultRightSprite()
        : dialog_ResolveSprite(_sprite_or_object);
    return {
        kind: "right",
        sprite: dialog_ValidatePortraitSprite(_spr, false),
        speaker_key: string_lower(string(_speaker_key)),
        visible: _visible
    };
}

function dialog_LeftVisible(_visible) {
    return { kind: "left_visible", visible: _visible };
}

function dialog_RightVisible(_visible) {
    return { kind: "right_visible", visible: _visible };
}

function dialog_HideLeft() {
    return dialog_LeftVisible(false);
}

function dialog_ShowLeft() {
    return dialog_LeftVisible(true);
}

function dialog_HideRight() {
    return dialog_RightVisible(false);
}

function dialog_ShowRight() {
    return dialog_RightVisible(true);
}

function dialog_Name(_key, _display_name) {
    return { kind: "name", key: string_lower(string(_key)), display: string(_display_name) };
}

function dialog_NameHero(_display_name) {
    return dialog_Name("hero", _display_name);
}

function dialog_NameGuide(_display_name) {
    return dialog_Name("guide", _display_name);
}

function dialog_ClearChars() {
    return { kind: "clear" };
}

function dialog_Background(_sprite_or_name = undefined, _visible = true) {
    return {
        kind: "background",
        sprite_ref: _sprite_or_name,
        visible: _visible
    };
}

function dialog_BackgroundVisible(_visible) {
    return { kind: "background_visible", visible: _visible };
}

function dialog_HideBackground() {
    return dialog_BackgroundVisible(false);
}

function dialog_ShowBackground() {
    return dialog_BackgroundVisible(true);
}

function dialog_ClearBackground() {
    return { kind: "clear_background" };
}

/// @param _speaker_key Short key such as hero / guide (uses namehero, nameguide, etc.)
function dialog_LineKey(_speaker_key, _text) {
    return {
        kind: "line",
        speaker_key: string_lower(string(_speaker_key)),
        text: string(_text)
    };
}

/// @desc Back-compat line — speaker can be a key (hero) or a display name (Hero)
function dialog_Line(_speaker, _text) {
    return {
        kind: "line",
        speaker_key: string_lower(string(_speaker)),
        speaker: string(_speaker),
        text: string(_text)
    };
}

function dialog_FromText(_text) {
    return dialog_ParseTextScript(_text);
}
