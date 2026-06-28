event_inherited();



eventmarker_apply_config(1, "Trail Start", "battle01", "Grasslands_Battleset01_starter.json", "battle01,battle02,battle03");



//reward amount, randomization

eventmarker_apply_reward(1, true);



//rewards( id, weigh percentage, one time gain

//example (1,20) (2,100) = 120 total weight → 20/120 = 16.67% for the 20-weight card

//once = true → that card can only be won once ever from any reward pool



eventmarker_reward_add(8, 100, "", true);   // one-time — never drops again after obtained

eventmarker_reward_add(9, 100);

eventmarker_reward_add(10, 100);

eventmarker_reward_add(10, 100);

eventmarker_reward_add(10, 100);

