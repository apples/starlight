class_name TurnTask extends CardTask

func start() -> void:
	var action_future := Future.new()
	battle_state.send_message_to(battle_state.current_turn, MessageTypes.TakeTurn.new({ action_future = action_future }))
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
	
	var location: ZoneLocation = payload.location
	var index: int = payload.ability_index
	assert(index == 0 or index == 1)
	
	var unit := battle_state.get_unit(location)
	assert(unit != null)
	if unit == null:
		push_error("Unit not found at: %s" % location)
		goto(start)
		return
	
	var ability: CardAbility = unit.card_instance.card.get_ability(index)
	assert(ability != null)
	if ability == null:
		push_error("Invalid ability index: %s" % index)
		goto(start)
		return
	
	if ability.effect == null:
		push_error("Ability has no effect! (index: %s)" % index)
		goto(start)
		return
	
	var ability_instance := battle_state.perform_ability(battle_state.current_turn, unit.card_instance, index)
	
	wait_for(ability_instance.task, activate_ability_finished)

func activate_ability_finished() -> void:
	battle_state.clear_events()
	goto(start)

#func process_retreat(_payload):
#	push_error("Not implemented")
#	goto(start)
#
#func process_pass(_payload):
#	end_turn()
#
#func end_turn():
#	battle_state.current_turn = ZoneLocation.flip(battle_state.current_turn)
#	run_task(TurnTask.new())
#	done()
