class_name TurnTask extends CardTask

enum TurnActionType {
	Card,
	Ability,
	Retreat,
	Pass,
}

class TurnAction:
	var type: TurnAction
	var payload: Dictionary

func start():
	var action_future := Future.new()
	battle_state.send_message_to(battle_state.current_turn, { type = "take_turn", action_future = action_future })
	wait_for_future(action_future, process_action)

func process_action(action: TurnAction):
	match action.type:
		TurnActionType.Card: return process_play_card(action.payload)
		TurnActionType.Ability: return process_use_ability(action.payload)
		TurnActionType.Retreat: return process_retreat(action.payload)
		TurnActionType.Pass: return process_pass(action.payload)
		_:
			push_error("Turn type not implemented")
			done(Result.FAILED)

func process_play_card(payload: Dictionary):
	wait_for(PlayCardTask.new(payload.card_instance, battle_state.turn_side), start)

func process_use_ability(payload: Dictionary):
	var unit = battle_state.get_unit(payload.location)
	var ability = unit.card_instance.card["ability%s" % payload.ability_index]
	
	if ability == null:
		push_error("Invalid attackIndex: %s" % payload.ability_index)
		goto(start)
		return
	
	var task = ability.effect.task()
	task.source_card_instance = unit.card_instance
	task.source_location = payload.location
	
	wait_for(task, start)

func process_retreat(_payload):
	push_error("Not implemented")
	goto(start)

func process_pass(_payload):
	end_turn()

func end_turn():
	battle_state.current_turn = BattleState.flip(battle_state.current_turn)
	run_task(TurnTask.new())
	done()
