event_inherited();

eventmarker_apply_config(1, "Trail Start", "battle01", "Grasslands_Battleset01_starter.json", "battle01,battle02,battle03");

//reward amount, randomization
eventmarker_apply_reward(3, true);

//rewards( id, weigh percentage
//example (1,20) (2,(100) = 120% 20/120 = 16.67% for the 20 dollar card

//
eventmarker_reward_add(8, 100);
eventmarker_reward_add(9, 100);
eventmarker_reward_add(10, 100);
eventmarker_reward_add(10, 100);
eventmarker_reward_add(10, 100);
