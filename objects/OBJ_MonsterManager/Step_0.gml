SCR_Monster_UpdateHoverDebug();

// Debug: press 1/2/3 to deal 5 damage to enemy slot 0/1/2
if (keyboard_check_pressed(ord("1"))) combat_DamageUnit(SIDE_ENEMY, 0, 5);
if (keyboard_check_pressed(ord("2"))) combat_DamageUnit(SIDE_ENEMY, 1, 5);
if (keyboard_check_pressed(ord("3"))) combat_DamageUnit(SIDE_ENEMY, 2, 5);
