global.mouse_left_pressed = mouse_check_button_pressed(mb_left);
click_processed = false;
SCR_DBS_HandleScrolling();
SCR_DBS_HandleDeckClick();
SCR_DBS_HandleReadyButton();
global.mouse_left_pressed = false;