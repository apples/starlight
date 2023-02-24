class_name RootBattleTask extends CardTask

func start():
	battle_state.shuffle_deck(BattleState.Side.Player)
	battle_state.shuffle_deck(BattleState.Side.Opponent)
	
	for i in range(battle_state.rules.startingHandSize):
		battle_state.draw_card(BattleState.Side.Player)
		battle_state.draw_card(BattleState.Side.Opponent)
	
	battle_state.summon_starters(BattleState.Side.Player)
	battle_state.summon_starters(BattleState.Side.Opponent)
	
	goto(start_first_turn)

func start_first_turn():
	battle_state.current_turn = BattleState.Side.Player
	run_task(TurnTask.new())
	done()
