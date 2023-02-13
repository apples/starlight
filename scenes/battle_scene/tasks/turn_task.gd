class_name TurnTask extends CardTask

func start() -> void:
	var action_future := Future.new()
	battle_state.send_message_to(battle_state.current_turn, { type = "take_turn", action_future = action_future })
	wait_for_future(action_future, process_action)

func process_action(action: Dictionary) -> void:
	var process_func_name: StringName = "process_%s" % action.type
	if self.has_method(process_func_name):
		self.call(process_func_name, action)
	else:
		print("Unknown action type: %s" % action)

func process_play_unit(action: Dictionary) -> void:
	battle_state.summon_unit(action.card, action.where)
	goto(start)
#
#func process_use_ability(payload: Dictionary):
#	var unit = battle_state.get_unit(payload.location)
#	var ability = unit.card_instance.card["ability%s" % payload.ability_index]
#
#	if ability == null:
#		push_error("Invalid attackIndex: %s" % payload.ability_index)
#		goto(start)
#		return
#
#	var task = ability.effect.task()
#	task.source_card_instance = unit.card_instance
#	task.source_location = payload.location
#
#	wait_for(task, start)
#
#func process_retreat(_payload):
#	push_error("Not implemented")
#	goto(start)
#
#func process_pass(_payload):
#	end_turn()
#
#func end_turn():
#	battle_state.current_turn = BattleState.flip(battle_state.current_turn)
#	run_task(TurnTask.new())
#	done()
