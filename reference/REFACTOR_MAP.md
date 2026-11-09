# Refactor map

Where every old script went, and which functions were removed. Generated during the refactor.

## Old script → new script(s)

| Old script | Now in |
|---|---|
| `deck_Clear` | `scr_deck` |
| `LoadCollection` | `scr_card_data` |
| `LoadMonsters` | `scr_monster_data` |
| `SCR_Battle_Attack` | `scr_battle_attack`, `scr_battle_play`, `scr_combat` |
| `SCR_Battle_Draw` | `scr_battle_manager` |
| `SCR_Battle_EnemyLog` | `scr_battle_log` |
| `SCR_Battle_EnemyTurn` | `scr_battle_turn` |
| `SCR_Battle_Init` | `scr_battle_manager`, `scr_battle_play` |
| `SCR_Battle_Load` | `scr_battle_session` |
| `SCR_Battle_PlayCard` | `scr_battle_play` |
| `SCR_Battle_PlayerHealth` | `scr_battle_player_health` |
| `SCR_Battle_Resources` | `scr_battle_resources` |
| `SCR_Battle_Session` | `scr_battle_session` |
| `SCR_Battle_SpiritShuffle` | `scr_battle_spirit_shuffle` |
| `SCR_Battle_Status` | `scr_status_effects` |
| `SCR_Battle_Step` | `scr_battle_manager` |
| `SCR_Battle_Targeting` | `scr_battle_targeting` |
| `SCR_Battle_Turn` | `scr_battle_play`, `scr_battle_turn` |
| `SCR_Battle_UI` | `scr_battle_ui` |
| `SCR_Board_ActionSlot` | removed — never called |
| `SCR_Board_Create` | `scr_board_setup` |
| `SCR_Board_Dimensions` | `scr_board_setup` |
| `SCR_Board_Draw` | `scr_board_draw` |
| `SCR_Board_EnemySlots` | `scr_board_setup` |
| `SCR_Board_PlayerSlots` | removed — never called |
| `SCR_Board_SlotManager` | `scr_board_slots` |
| `SCR_Card_Cost` | `scr_card_costs` |
| `SCR_Card_Draw` | `scr_card_draw` |
| `SCR_CardSlot_AddToDeck` | `scr_collection_cardslot` |
| `SCR_CardSlot_CheckClick` | removed — never called |
| `SCR_CardSlot_CheckVisibility` | `scr_collection_cardslot` |
| `SCR_CardSlot_Draw` | `scr_collection_cardslot` |
| `SCR_CardSlot_DrawBackground` | `scr_collection_cardslot` |
| `SCR_CardSlot_DrawCountBadge` | `scr_collection_cardslot` |
| `SCR_CardSlot_DrawLevel` | `scr_collection_cardslot` |
| `SCR_CardSlot_DrawPicture` | `scr_collection_cardslot` |
| `SCR_CardSlot_DrawText` | `scr_collection_cardslot` |
| `SCR_CardSlot_Hover` | removed — never called |
| `SCR_CardSlot_VisualFeedback` | removed — never called |
| `SCR_CardSlotCreate` | removed — never called |
| `SCR_Conditions` | `scr_card_conditions`, `scr_card_data` |
| `SCR_DBC_Create` | `scr_deckbuilder_setup` |
| `SCR_DBC_InitContainer` | `scr_deckbuilder_setup` |
| `SCR_DBC_InitDeck` | `scr_deckbuilder_setup` |
| `SCR_DBC_InitGrid` | `scr_deckbuilder_setup` |
| `SCR_DBC_InitPagination` | `scr_deckbuilder_setup` |
| `SCR_DBC_LoadPage` | `scr_deckbuilder_setup` |
| `SCR_DBD_Collection` | `scr_deckbuilder_collection` |
| `SCR_DBD_Draw` | `scr_deckbuilder_draw` |
| `SCR_DBD_DrawContainer` | `scr_deckbuilder_draw` |
| `SCR_DBD_DrawDeckInfo` | `scr_deckbuilder_draw` |
| `SCR_DBD_DrawDeckList` | `scr_deckbuilder_draw` |
| `SCR_DBS_HandleDeckClick` | `scr_deckbuilder_input` |
| `SCR_DBS_HandleReadyButton` | — |
| `SCR_DBS_HandleScrolling` | `scr_deckbuilder_input` |
| `SCR_Debug` | `scr_debug` |
| `SCR_Deck_CardPicker` | `scr_deck_picker` |
| `SCR_Deck_createinit` | `scr_card_data`, `scr_deck` |
| `SCR_Deck_Draw` | `scr_deck_draw` |
| `SCR_Deck_DrawDebugRow` | `scr_deck_draw` |
| `SCR_Deck_ExtraDeck` | `scr_deck_extra` |
| `SCR_Dialog_Builder` | `scr_dialog_builder` |
| `SCR_Dialog_System` | `scr_dialog_system` |
| `SCR_Dialog_Text` | `scr_dialog_text` |
| `SCR_DialogExample_map1marker` | `scr_dialog_map1` |
| `SCR_DialogExample_map2markers` | `scr_dialog_map2` |
| `SCR_DragDrop_Init` | `scr_board_dragdrop` |
| `SCR_EventMaker` | `scr_worldmap_events` |
| `SCR_ExtraDeck_Create` | `scr_deckbuilder_extradeck` |
| `SCR_ExtraDeck_Draw` | `scr_deckbuilder_extradeck` |
| `SCR_ExtraDeck_DrawCard` | `scr_deckbuilder_extradeck` |
| `SCR_ExtraDeck_Step` | `scr_deckbuilder_extradeck` |
| `SCR_Hand_Create` | `scr_hand` |
| `SCR_Hand_Draw` | `scr_hand_draw` |
| `SCR_Hand_DrawCard` | `scr_hand_draw` |
| `SCR_Hand_DrawFromDeck` | `scr_hand` |
| `SCR_Hand_GetSpacing` | `scr_hand_draw` |
| `SCR_Hand_GetSprite` | `scr_hand` |
| `SCR_Hand_Init` | `scr_hand` |
| `SCR_Hand_IsHovered` | `scr_hand_draw` |
| `SCR_Hand_Layout` | `scr_hand_draw` |
| `SCR_HoverEffect` | `scr_deckbuilder_draw` |
| `SCR_Monster_AnimRegistry` | `scr_monster_anim` |
| `SCR_Monster_AnimShared` | `scr_monster_anim` |
| `SCR_Monster_Data` | `scr_monster_data` |
| `SCR_Monster_Draw` | `scr_monster_draw` |
| `SCR_Monster_HoverDebug` | `scr_monster_draw` |
| `SCR_Monster_Init` | `scr_monster_manager` |
| `SCR_Monster_Queue` | `scr_monster_manager` |
| `SCR_MonsterAbility_AddDeck` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAbility_Attack` | `scr_enemy_abilities` |
| `SCR_MonsterAbility_AttackAll` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAbility_Buff` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAbility_Core` | `scr_enemy_ai` |
| `SCR_MonsterAbility_Delayed` | `scr_enemy_ai` |
| `SCR_MonsterAbility_DiscardExtraDeck` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAbility_DiscardHand` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAbility_Execute` | `scr_enemy_abilities`, `scr_enemy_ai` |
| `SCR_MonsterAbility_Picker` | `scr_enemy_picker` |
| `SCR_MonsterAbility_SelfBuff` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAbility_SummonEnemy` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAbility_TimedBuff` | `scr_status_effects` (rewritten) |
| `SCR_MonsterAbility_TraitRelay` | `scr_enemy_abilities` (rewritten) |
| `SCR_MonsterAnim_GoblinCommander` | `scr_monster_anim` |
| `SCR_MonsterAnim_GoblinMage` | `scr_monster_anim` |
| `SCR_MonsterAnim_GoblinSoldier` | `scr_monster_anim` |
| `SCR_MonsterAnim_OrcBrute` | `scr_monster_anim` |
| `SCR_MonsterAnim_OrcShaman` | `scr_monster_anim` |
| `SCR_PlayerCollection` | `scr_player_collection` |
| `SCR_RoomGoto` | `scr_room_goto` |
| `SCR_Slot_init` | `scr_board_setup` |
| `SCR_Trait_AddDeck` | `scr_card_effects` (rewritten) |
| `SCR_Trait_AddHand` | `scr_card_effects` (rewritten) |
| `SCR_Trait_AddTag` | `scr_card_data`, `scr_card_search_picker`, `scr_trait_parse` |
| `SCR_Trait_Attack` | `scr_card_effects` (rewritten) |
| `SCR_Trait_AttackAll` | `scr_card_effects` (rewritten) |
| `SCR_Trait_BuffAttack` | `scr_combat`, `scr_card_effects` (rewritten) |
| `SCR_Trait_Destroy` | `scr_card_effects` (rewritten) |
| `SCR_Trait_Draw` | `scr_trait_parse`, `scr_card_effects` (rewritten) |
| `SCR_Trait_Execute` | `scr_trait_execute` |
| `SCR_Trait_Heal` | `scr_card_data`, `scr_card_effects` (rewritten) |
| `SCR_Trait_HealAll` | `scr_card_effects` (rewritten) |
| `SCR_Trait_OpenZone` | `scr_card_effects` |
| `SCR_Trait_Parse` | `scr_trait_execute`, `scr_trait_parse` |
| `SCR_Trait_Resources` | `scr_trait_execute` |
| `SCR_Trait_Silence` | `scr_status_effects`, `scr_card_effects` (rewritten) |
| `SCR_WorldMap_Config` | `scr_worldmap_config` |
| `SCR_WorldMap_Controller` | `scr_worldmap_controller` |
| `SCR_WorldMap_Progress` | `scr_worldmap_progress` |
| `SlotFactory` | `scr_board_setup` |

`SCR_Trait_MonsterAbility.gml` was an orphaned file (not registered in the project, never compiled) and was deleted.

## Removed or replaced functions

| Function | Was in | Now |
|---|---|---|
| `battle_ActionAttack` | `SCR_Battle_Attack` | removed — was never called |
| `battle_ActionHeal` | `SCR_Battle_Attack` | removed — was never called |
| `battle_BeginWeaponAttack` | `SCR_Battle_Attack` | `battle_BeginColumnAttack` |
| `battle_BeginWeaponAttackStrike` | `SCR_Battle_Attack` | `battle_BeginColumnAttack` |
| `battle_CanWeaponAttack` | `SCR_Battle_Attack` | `battle_CanColumnAttack` |
| `battle_ColumnExecuteAttackAll` | `SCR_Battle_Attack` | `battle_ColumnAttackAll` |
| `battle_ExecuteActionAttack` | `SCR_Battle_Attack` | `battle_ExecuteActionAttack("attack", targets)` (now includes the attacker's buff) |
| `battle_ExecuteActionBuff` | `SCR_Battle_Attack` | `battle_ResolvePendingTrait(["buff"], ...)` |
| `battle_ExecuteActionDestroy` | `SCR_Battle_Attack` | `battle_ResolvePendingTrait(["destroy", "silence"], ...)` |
| `battle_ExecuteActionHeal` | `SCR_Battle_Attack` | `battle_ResolvePendingTrait(["heal"], ...)` |
| `battle_ExecuteActionSelfBuff` | `SCR_Battle_Attack` | `battle_ResolvePendingTrait(["self_buff"], ...)` |
| `battle_ExecuteActionSilence` | `SCR_Battle_Attack` | `battle_ResolvePendingTrait(["destroy", "silence"], ...)` |
| `battle_FindActionTraitIndex` | `SCR_Battle_Attack` | removed — was never called |
| `battle_GetColumnWeaponStrikeDamage` | `SCR_Battle_Attack` | removed — was never called |
| `battle_GetMonsterAttackAllAmount` | `SCR_Battle_Attack` | `card_GetTraitAmount(x, "attack_all")` |
| `battle_GetWeaponColumnAt` | `SCR_Battle_Attack` | `battle_GetAttackColumnAt` |
| `battle_IsSpiritMonster` | `SCR_Battle_Attack` | `card_IsSpiritType` |
| `battle_MonsterAbilityAttack` | `SCR_Battle_Attack` | removed — was never called |
| `battle_MonsterAbilityHeal` | `SCR_Battle_Attack` | removed — was never called |
| `battle_MonsterAttackAll` | `SCR_Battle_Attack` | removed — was never called |
| `battle_MonsterUsesAttackAll` | `SCR_Battle_Attack` | removed — was never called |
| `battle_WeaponAttack` | `SCR_Battle_Attack` | `battle_ColumnAttack` |
| `battle_WeaponAttackAll` | `SCR_Battle_Attack` | removed — was never called |
| `weapon_GetAttackAllAmount` | `SCR_Battle_Attack` | `card_GetTraitAmount(x, "attack_all")` |
| `weapon_GetEffectRecursion` | `SCR_Battle_Attack` | removed — was never called |
| `weapon_UsesAttackAll` | `SCR_Battle_Attack` | removed — was never called |
| `battle_EnemyLog_Attack` | `SCR_Battle_EnemyLog` | removed — was never called |
| `battle_EnemyLog_BuffAttack` | `SCR_Battle_EnemyLog` | removed — was never called |
| `battle_EnemyLog_Heal` | `SCR_Battle_EnemyLog` | removed — was never called |
| `battle_EnemyLog_MonsterLabel` | `SCR_Battle_EnemyLog` | removed — was never called |
| `battle_EnemyLog_Skipped` | `SCR_Battle_EnemyLog` | removed — was never called |
| `battle_EnemyTurn_GetLiveMonster` | `SCR_Battle_EnemyTurn` | `unit_Get(SIDE_ENEMY, ` |
| `battle_GetHoveredEnemySlot` | `SCR_Battle_Init` | removed — was never called |
| `battle_NormalizeCollectionName` | `SCR_Battle_Load` | `monster_NormalizeCollectionName` |
| `battle_BeginEnemyTargetMode` | `SCR_Battle_PlayCard` | `battle_BeginOnPlayTargetMode` |
| `battle_BeginMonsterOnPlayTargeting` | `SCR_Battle_PlayCard` | `battle_BeginOnPlayTargeting("monster", ...)` |
| `battle_BeginPlayerTargetMode` | `SCR_Battle_PlayCard` | `battle_BeginOnPlayTargetMode` |
| `battle_BeginWeaponOnPlayTargeting` | `SCR_Battle_PlayCard` | `battle_BeginOnPlayTargeting("weapon", ...)` |
| `battle_ExecuteMonsterOnPlayBuffTrait` | `SCR_Battle_PlayCard` | `battle_ExecutePendingTrait` |
| `battle_ExecuteMonsterOnPlayEnemyTrait` | `SCR_Battle_PlayCard` | `battle_ExecutePendingTrait` |
| `battle_ExecuteMonsterOnPlayHealTrait` | `SCR_Battle_PlayCard` | `battle_ExecutePendingTrait` |
| `battle_ExecuteWeaponOnPlayBuffTrait` | `SCR_Battle_PlayCard` | `battle_ExecutePendingTrait` |
| `battle_ExecuteWeaponOnPlayEnemyTrait` | `SCR_Battle_PlayCard` | `battle_ExecutePendingTrait` |
| `battle_ExecuteWeaponOnPlayHealTrait` | `SCR_Battle_PlayCard` | `battle_ExecutePendingTrait` |
| `battle_FindActionTraitIndexOnCard` | `SCR_Battle_PlayCard` | removed — was never called |
| `battle_FindFirstTargetingTraitIndex` | `SCR_Battle_PlayCard` | removed — was never called |
| `battle_GetWeaponSlotCard` | `SCR_Battle_PlayCard` | removed — was never called |
| `battle_HasPlayerMonsterOnBoard` | `SCR_Battle_PlayCard` | `(unit_Count(SIDE_PLAYER) > 0)` |
| `battle_MonsterOnPlayContinue` | `SCR_Battle_PlayCard` | `battle_OnPlayContinue("monster", ...)` |
| `battle_OnMonsterPlayed` | `SCR_Battle_PlayCard` | `battle_OnBoardCardPlayed("monster", ...)` |
| `battle_OnWeaponPlayed` | `SCR_Battle_PlayCard` | `battle_OnBoardCardPlayed("weapon", ...)` |
| `battle_WeaponOnPlayContinue` | `SCR_Battle_PlayCard` | `battle_OnPlayContinue("weapon", ...)` |
| `card_HasAstralCondition` | `SCR_Battle_Session` | `card_IsAstral` |
| `status_DecrementEnemySilence` | `SCR_Battle_Status` | removed — was never called |
| `status_DecrementPlayerSilence` | `SCR_Battle_Status` | `status_TickPlayerUnitsAtTurnStart` |
| `battle_GetEnemySlotAt` | `SCR_Battle_Targeting` | `unit_GetSlotAt(SIDE_ENEMY, ` |
| `battle_GetPlayerMonsterSlotAt` | `SCR_Battle_Targeting` | `unit_GetSlotAt(SIDE_PLAYER, ` |
| `battle_HandleAnyBuffPick` | `SCR_Battle_Targeting` | `battle_TargetingClickPlayerSlot / battle_TargetingClickEnemySlot` |
| `battle_HandleEnemyTargetPick` | `SCR_Battle_Targeting` | `battle_TargetingClickEnemySlot` |
| `battle_DamagePlayerSide` | `SCR_Battle_Turn` | `targets_AttackDefender + card_Damage` |
| `battle_GetPlayerMonsterCard` | `SCR_Battle_Turn` | `unit_Get(SIDE_PLAYER, ` |
| `battle_IsOccupiedPlayerMonsterSlot` | `SCR_Battle_Turn` | `unit_IsAlive(SIDE_PLAYER, ` |
| `battle_PickRandomPlayerMonsterSlot` | `SCR_Battle_Turn` | `unit_PickRandom(SIDE_PLAYER)` |
| `battle_PlayerMonsterCount` | `SCR_Battle_Turn` | `unit_Count(SIDE_PLAYER)` |
| `trait_ExecuteAddBoardTurns` | `SCR_Battle_Turn` | `card_AddBoardTurns` |
| `trait_ExecuteNoBoardExpire` | `SCR_Battle_Turn` | `card_SetNoBoardExpire` |
| `battle_FindEnemySlotForCard` | `SCR_Battle_UI` | `unit_FindSlotOfCard(SIDE_ENEMY, ` |
| `SCR_Board_ActionSlot` | `SCR_Board_ActionSlot` | removed — was never called |
| `SCR_Board_InitSlots` | `SCR_Board_Draw` | removed — was never called |
| `SCR_Board_PlayerSlots` | `SCR_Board_PlayerSlots` | removed — was never called |
| `SCR_CardSlot_CheckClick` | `SCR_CardSlot_CheckClick` | removed — was never called |
| `SCR_CardSlot_UpdateHover` | `SCR_CardSlot_Hover` | removed — was never called |
| `SCR_CardSlot_VisualFeedback` | `SCR_CardSlot_VisualFeedback` | removed — was never called |
| `SCR_CardSlotCreate` | `SCR_CardSlotCreate` | removed — was never called |
| `card_IsAstral` | `SCR_Conditions` | still exists (moved/rewritten) |
| `conditions_CardHasTag` | `SCR_Conditions` | `card_HasAnyTag` |
| `conditions_CardMatchesTypeFilter` | `SCR_Conditions` | `card_MatchesAnyType` |
| `conditions_FindEmptyMonsterSlot` | `SCR_Conditions` | removed — was never called |
| `deck_DebugPrint` | `SCR_Deck_createinit` | removed — was never called |
| `deck_IsValid` | `SCR_Deck_createinit` | removed — was never called |
| `monster_ApplyDamage` | `SCR_Monster_Queue` | `combat_DamageUnit(SIDE_ENEMY, ` |
| `monsterAbility_AddDeck_Activate` | `SCR_MonsterAbility_AddDeck` | `monsterAbility_AddCardsToPlayerDeck` |
| `monsterAbility_attack_all` | `SCR_MonsterAbility_AttackAll` | `monsterAbility_RunEffect` |
| `monsterAbility_AttackAll_Activate` | `SCR_MonsterAbility_AttackAll` | `monsterAbility_RunEffect` |
| `monsterAbility_AttackAll_Perform` | `SCR_MonsterAbility_AttackAll` | `monsterAbility_PerformAttack` |
| `monsterAbility_buff` | `SCR_MonsterAbility_Buff` | `monsterAbility_BuffWithTimer` |
| `monsterAbility_Buff_Activate` | `SCR_MonsterAbility_Buff` | `monsterAbility_BuffWithTimer` |
| `battle_EnemyPickBuffAllyTarget` | `SCR_MonsterAbility_Core` | `monsterAbility_PickBuffTarget` |
| `battle_EnemyPickBuffTarget` | `SCR_MonsterAbility_Core` | removed — was never called |
| `battle_EnemyPickHealTarget` | `SCR_MonsterAbility_Core` | `monsterAbility_PickHealTarget` |
| `monsterAbility_DiscardExtraDeck_Activate` | `SCR_MonsterAbility_DiscardExtraDeck` | `monsterAbility_BeginDiscardExtraDeck` |
| `monsterAbility_DiscardHand_Activate` | `SCR_MonsterAbility_DiscardHand` | `monsterAbility_BeginDiscardHand` |
| `monsterAbility_ApplyDelayedEffect` | `SCR_MonsterAbility_Execute` | rewritten in scr_enemy_abilities (uses trait_Execute / card_*) |
| `monsterAbility_self_buff` | `SCR_MonsterAbility_SelfBuff` | `monsterAbility_BuffWithTimer` |
| `monsterAbility_SelfBuff_Activate` | `SCR_MonsterAbility_SelfBuff` | `monsterAbility_BuffWithTimer` |
| `monsterAbility_SummonEnemy_Activate` | `SCR_MonsterAbility_SummonEnemy` | `monsterAbility_RunEffect` |
| `monsterAbility_ApplyTimedBuff` | `SCR_MonsterAbility_TimedBuff` | `status_Apply(unit, STATUS_TIMED_ATTACK_BUFF, turns, { amount, source_name })` |
| `monsterAbility_InitTimedBuffs` | `SCR_MonsterAbility_TimedBuff` | `status_InitTimedBuffs` |
| `monsterAbility_TickAllTimedBuffs` | `SCR_MonsterAbility_TimedBuff` | `status_TickAllTimedAttackBuffs` |
| `monsterAbility_TickTimedBuffsOnUnit` | `SCR_MonsterAbility_TimedBuff` | `status_Tick(unit, STATUS_TIMED_ATTACK_BUFF)` |
| `monsterAbility_TraitRelay_Activate` | `SCR_MonsterAbility_TraitRelay` | `monsterAbility_RunEffect` |
| `monsterAbility_TraitRelay_IsSharedType` | `SCR_MonsterAbility_TraitRelay` | `monsterAbility_HasEffect` |
| `trait_CreateAddDeckContext` | `SCR_Trait_AddDeck` | `trait_CreateContext` |
| `trait_CreateAddExtraDeckContext` | `SCR_Trait_AddDeck` | `trait_CreateContext` |
| `trait_ExecuteAddDeck` | `SCR_Trait_AddDeck` | `card_AddToDeck` |
| `trait_ExecuteAddExtraDeck` | `SCR_Trait_AddDeck` | `card_AddToExtraDeck` |
| `trait_CreateAddHandContext` | `SCR_Trait_AddHand` | `trait_CreateContext` |
| `trait_ExecuteAddHand` | `SCR_Trait_AddHand` | `card_AddToHand` |
| `card_HasAnyTag` | `SCR_Trait_AddTag` | still exists (moved/rewritten) |
| `card_IsExtraDeckType` | `SCR_Trait_AddTag` | `card_IsSpiritType` |
| `trait_ExecuteAddDeckTag` | `SCR_Trait_AddTag` | `deck_TagPicker_Begin` |
| `trait_ExecuteAddExtraDeckTag` | `SCR_Trait_AddTag` | `deck_TagPicker_Begin` |
| `trait_ExecuteAddHandTag` | `SCR_Trait_AddTag` | `deck_TagPicker_Begin` |
| `trait_ExecuteAddHandWithCost` | `SCR_Trait_AddTag` | `trait_Execute case "add_hand_with_cost"` |
| `trait_CreateAttackContext` | `SCR_Trait_Attack` | `trait_CreateContext` |
| `trait_ExecuteAttack` | `SCR_Trait_Attack` | `card_Damage` |
| `trait_AttackAllEnemies` | `SCR_Trait_AttackAll` | `card_Damage + targets_All(SIDE_ENEMY)` |
| `trait_AttackAllPlayerMonsters` | `SCR_Trait_AttackAll` | `card_Damage + targets_AllOpponents` |
| `trait_CreateAttackAllContext` | `SCR_Trait_AttackAll` | `trait_CreateContext` |
| `trait_ExecuteAttackAll` | `SCR_Trait_AttackAll` | `card_Damage + targets_AllOpponents` |
| `battle_BuffEnemyMonster` | `SCR_Trait_BuffAttack` | `card_BuffAttack` |
| `battle_BuffPlayerMonster` | `SCR_Trait_BuffAttack` | `card_BuffAttack` |
| `battle_ExecuteBuffAt` | `SCR_Trait_BuffAttack` | `card_BuffAttack` |
| `battle_PickRandomAnyBuffTarget` | `SCR_Trait_BuffAttack` | `targets_AnyUnit` |
| `trait_CreateBuffAttackContext` | `SCR_Trait_BuffAttack` | `trait_CreateContext` |
| `trait_ExecuteBuffAttack` | `SCR_Trait_BuffAttack` | `card_BuffAttack` |
| `battle_DestroyEnemyMonster` | `SCR_Trait_Destroy` | `combat_RemoveUnit(SIDE_ENEMY, ` |
| `trait_CreateDestroyContext` | `SCR_Trait_Destroy` | `trait_CreateContext` |
| `trait_DestroyEnemyCount` | `SCR_Trait_Destroy` | removed — was never called |
| `trait_ExecuteDestroy` | `SCR_Trait_Destroy` | `card_Destroy` |
| `trait_PickLowestHpEnemySlot` | `SCR_Trait_Destroy` | replaced by card_Destroy / combat_RemoveUnit (trait_DestroyEnemyCount, trait_PickLowestHpEnemySlot were unused) |
| `trait_CreateDrawContext` | `SCR_Trait_Draw` | `trait_CreateContext` |
| `trait_ExecuteDraw` | `SCR_Trait_Draw` | `card_DrawCards` |
| `trait_ExecuteByType` | `SCR_Trait_Execute` | removed — was never called |
| `battle_DamagePlayerMonster` | `SCR_Trait_Heal` | `combat_DamageUnit(SIDE_PLAYER, ` |
| `battle_DestroyPlayerMonster` | `SCR_Trait_Heal` | `combat_RemoveUnit(SIDE_PLAYER, ` |
| `battle_HealEnemyMonster` | `SCR_Trait_Heal` | `card_Heal` |
| `battle_HealPlayerMonster` | `SCR_Trait_Heal` | `card_Heal` |
| `trait_CreateHealContext` | `SCR_Trait_Heal` | `trait_CreateContext` |
| `trait_ExecuteHeal` | `SCR_Trait_Heal` | `card_Heal` |
| `trait_CreateHealAllContext` | `SCR_Trait_HealAll` | `trait_CreateContext` |
| `trait_ExecuteHealAll` | `SCR_Trait_HealAll` | `card_Heal + targets_AllAllies` |
| `trait_HealAllEnemies` | `SCR_Trait_HealAll` | `card_Heal + targets_AllAllies` |
| `trait_HealAllPlayerMonsters` | `SCR_Trait_HealAll` | `card_Heal + targets_AllAllies` |
| `trait_ExecuteOpenZone` | `SCR_Trait_OpenZone` | `card_OpenZones` |
| `battle_ExecuteActionAddCost` | `SCR_Trait_Resources` | `battle_ExecutePendingTrait` |
| `battle_ExecuteMonsterOnPlayAddCostTrait` | `SCR_Trait_Resources` | `battle_ExecutePendingTrait` |
| `battle_ExecuteWeaponOnPlayAddCostTrait` | `SCR_Trait_Resources` | `battle_ExecutePendingTrait` |
| `battle_HandleAddCostPick` | `SCR_Trait_Resources` | `battle_ResolvePendingTrait(["add_cost"], [], card)` |
| `battle_PickAddCostTargetAt` | `SCR_Trait_Resources` | `battle_FindPlayerCardAt` |
| `trait_ExecuteAddCounter` | `SCR_Trait_Resources` | `card_AddResourceCounter` |
| `trait_ExecuteRemoveCounter` | `SCR_Trait_Resources` | `card_RemoveResourceCounter` |
| `battle_ShroudPlayerMonster` | `SCR_Trait_Silence` | `card_Shroud` |
| `battle_SilenceEnemyMonster` | `SCR_Trait_Silence` | `card_Silence` |
| `battle_SilencePlayerMonster` | `SCR_Trait_Silence` | removed — was never called |
| `trait_CreateShroudContext` | `SCR_Trait_Silence` | `trait_CreateContext` |
| `trait_CreateSilenceContext` | `SCR_Trait_Silence` | `trait_CreateContext` |
| `trait_ExecuteShroud` | `SCR_Trait_Silence` | `card_Shroud` |
| `trait_ExecuteSilence` | `SCR_Trait_Silence` | `card_Silence` |
| `conditions_HandCountOfType` | `SCR_Conditions` | `conditions_CountHandCards({ types })` |
| `conditions_CountHandDiscardTagCandidates` | `SCR_Conditions` | `conditions_CountHandCards({ tags, types })` |
| `conditions_CountOccupiedMonsters` | `SCR_Conditions` | `conditions_CountBoardMonsters` |
| `conditions_CountOccupiedMonstersById` | `SCR_Conditions` | `conditions_CountBoardMonsters({ id })` |
| `conditions_CountHandCardsById` | `SCR_Conditions` | `conditions_CountHandCards({ id })` |
| `battle_RunEnemyTurn` | `SCR_Battle_EnemyTurn` | `battle_BeginEnemyTurn` |
| `monsterAbility_ApplyDelayedEffect` | `SCR_MonsterAbility_Execute` | removed — it never applied an effect |
| `battle_IsActionCardFinished` | `SCR_Battle_PlayCard` | `battle_FinishActionCard` (a spent action card always leaves the slot) |
| `battle_ClearActionSlotIfFinished` | `SCR_Battle_PlayCard` | `battle_FinishActionCard` |
