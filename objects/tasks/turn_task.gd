class_name TurnTask extends CardTask

func start() -> void:
	
	var available_abilities: Dictionary = battle_state.get_available_activations(battle_state.current_turn)
	
	var available_summons := battle_state.get_available_summons(battle_state.current_turn)
	
	var action_future := Future.new()
	battle_state.send_message_to(
		battle_state.current_turn,
		MessageTypes.TakeTurn.new({
			action_future = action_future,
			available_abilities = available_abilities,
			available_summons = available_summons,
		}))
	wait_for_future(action_future, process_action)

func process_action(action: Dictionary) -> void:
	assert("type" in action)
	if "type" not in action:
		print("Invalid payload: %s" % action)
		goto(start)
		return
	var process_func_name: StringName = "process_%s" % action.type
	if self.has_method(process_func_name):
		self.call(process_func_name, action)
	else:
		print("Unknown action type: %s" % action)
		goto(start)

func process_play_unit(action: Dictionary) -> void:
	battle_state.unit_summon(action.card, action.where)
	goto(start)

func process_activate_ability(payload: Dictionary):
	assert("location" in payload)
	assert("ability_index" in payload)
	
	if "location" not in payload or "ability_index" not in payload:
		print("Invalid payload: %s" % payload)
		goto(start)
		return
	
	var location: ZoneLocation = payload.location
	
	var card_instance := battle_state.get_card_at(location)
	
	var index: int = payload.ability_index
	assert(index >= 0)
	assert(index < card_instance.card.abilities.size())
	
	match card_instance.card.kind:
		Card.Kind.UNIT:
			return _process_activate_ability_unit(card_instance, index)
		Card.Kind.GRACE:
			return _process_activate_ability_grace(card_instance, index)
		Card.Kind.STELLA:
			return _process_activate_ability_stella(card_instance, index)
	

func _process_activate_ability_unit(card_instance: CardInstance, index: int):
	var unit := card_instance.unit
	assert(unit != null)
	if unit == null:
		print("Unit not found at: %s" % card_instance.location)
		goto(start)
		return
	
	var ability: CardAbility = card_instance.card.abilities[index]
	assert(ability != null)
	if ability == null:
		print("Invalid ability index: %s" % index)
		goto(start)
		return
	
	if ability.effect == null:
		print("Ability has no effect! (index: %s)" % index)
		goto(start)
		return
	
	var ability_instance := battle_state.ability_perform(battle_state.current_turn, unit.card_instance, index)
	
	wait_for(ability_instance.task, activate_ability_finished)

func _process_activate_ability_grace(card_instance: CardInstance, index: int):
	var ability: CardAbility = card_instance.card.abilities[index]
	assert(ability != null)
	if ability == null:
		print("Invalid ability index: %s" % index)
		goto(start)
		return
	
	if ability.effect == null:
		print("Ability has no effect! (index: %s)" % index)
		goto(start)
		return
	
	var ability_instance := battle_state.ability_perform(battle_state.current_turn, card_instance, index)
	
	wait_for(ability_instance.task, activate_ability_finished)

func _process_activate_ability_stella(card_instance: CardInstance, index: int):
	var ability: CardAbility = card_instance.card.abilities[index]
	assert(ability != null)
	if ability == null:
		print("Invalid ability index: %s" % index)
		goto(start)
		return
	
	if ability.effect == null:
		print("Ability has no effect! (index: %s)" % index)
		goto(start)
		return
	
	var ability_instance := battle_state.ability_perform(battle_state.current_turn, card_instance, index)
	
	wait_for(ability_instance.task, activate_ability_finished)


func activate_ability_finished() -> void:
	battle_state.trigger_events_clear()
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
