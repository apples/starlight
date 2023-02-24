class_name TurnTask extends CardTask

func start() -> void:
	var action_future := Future.new()
	battle_state.send_message_to(battle_state.current_turn, { type = "take_turn", action_future = action_future })
	wait_for_future(action_future, process_action)

func process_action(action: Dictionary) -> void:
	assert("type" in action)
	if "type" not in action:
		push_error("Invalid payload: %s" % action)
		goto(start)
		return
	var process_func_name: StringName = "process_%s" % action.type
	if self.has_method(process_func_name):
		self.call(process_func_name, action)
	else:
		print("Unknown action type: %s" % action)
		goto(start)

func process_play_unit(action: Dictionary) -> void:
	battle_state.summon_unit(action.card, action.where)
	goto(start)

func process_activate_ability(payload: Dictionary):
	assert("location" in payload)
	assert("ability_index" in payload)
	
	if "location" not in payload or "ability_index" not in payload:
		push_error("Invalid payload: %s" % payload)
		goto(start)
		return
	
	var location: BattleState.ZoneLocation = payload.location
	var index: int = payload.ability_index
	assert(index == 1 or index == 2)
	
	var unit := battle_state.get_unit(location)
	assert(unit != null)
	if unit == null:
		push_error("Unit not found at: %s" % location)
		goto(start)
		return
	
	var ability: CardAbility = unit.card_instance.card["ability%s" % index]
	assert(ability != null)
	if ability == null:
		push_error("Invalid ability index: %s" % index)
		goto(start)
		return
	
	ability.cost
	
	if ability.effect == null:
		push_error("Ability has no effect! (index: %s)" % index)
		goto(start)
		return
	
	var task := ability.effect.task()
	task.source_card_instance = unit.card_instance
	task.source_location = location
	
	wait_for(task, start)

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
