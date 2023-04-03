class_name RootBattleTask extends CardTask

func start():
	battle_state.shuffle_deck(ZoneLocation.Side.Player)
	battle_state.shuffle_deck(ZoneLocation.Side.Opponent)
	
	battle_state.init_stella(ZoneLocation.Side.Player)
	battle_state.init_stella(ZoneLocation.Side.Opponent)
	
	battle_state.summon_starters(ZoneLocation.Side.Player)
	battle_state.summon_starters(ZoneLocation.Side.Opponent)
	
	for i in range(battle_state.rules.startingHandSize):
		battle_state.draw_card(ZoneLocation.Side.Player)
		battle_state.draw_card(ZoneLocation.Side.Opponent)
	
	goto(start_first_turn)

func start_first_turn():
	battle_state.current_turn = ZoneLocation.Side.Player
	wait_for(TurnTask.new(), next_turn)

func next_turn():
	battle_state.setup_next_turn()
	wait_for(TurnTask.new(), next_turn)
