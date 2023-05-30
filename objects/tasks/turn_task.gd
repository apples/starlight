class_name TurnTask extends CardTask

var _summoning_card: CardInstance

func start() -> void:
	var side_state := battle_state.get_side_state(battle_state.current_turn)
	
	# Untap, Upkeep, Draw
	for unit in side_state.front_row:
		if unit:
			battle_state.unit_set_tapped(unit, false)
	for unit in side_state.back_row:
		if unit:
			battle_state.unit_set_tapped(unit, false)
	battle_state.draw_card(battle_state.current_turn)
	
	goto(neutral)

func neutral() -> void:
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
		goto(neutral)
		return
	var process_func_name: StringName = "process_%s" % action.type
	if self.has_method(process_func_name):
		self.call(process_func_name, action)
	else:
		print("Unknown action type: %s" % action)
		goto(neutral)

func process_play_unit(action: Dictionary) -> void:
	if not _require(action, ["uid"]):
		return goto(neutral)
	
	var card_instance := battle_state.get_card_instance(action.uid)
	
	assert(card_instance)
	if not card_instance:
		print("Invalid payload: %s" % action)
		return goto(neutral)
	
	_summoning_card = card_instance
	
	var allowed_locations := battle_state.unit_get_summon_locations(card_instance)
	
	var location_future := Future.new()
	battle_state.send_message_to(
		battle_state.current_turn,
		MessageTypes.ChooseFieldLocation.new({
			future = location_future,
			allowed_locations = allowed_locations,
		}))
	
	wait_for_future(location_future, _process_play_unit_location_chosen)

func _process_play_unit_location_chosen(location: ZoneLocation) -> void:
	var allowed_locations := battle_state.unit_get_summon_locations(_summoning_card)
	
	var found := false
	for al in allowed_locations:
		if al.equals(location):
			found = true
			break
	assert(found)
	if not found:
		print("Invalid payload: %s" % location)
		return goto(neutral)
	
	battle_state.unit_summon(_summoning_card, location)
	goto(neutral)

func process_activate_ability(payload: Dictionary) -> void:
	if not _require(payload, ["uid", "ability_index"]):
		return goto(neutral)
	
	var card_instance := battle_state.get_card_instance(payload.uid)
	
	assert(card_instance)
	if not card_instance:
		print("Invalid payload: %s" % payload)
		return goto(neutral)
	
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
	

func _process_activate_ability_unit(card_instance: CardInstance, index: int) -> void:
	var unit := card_instance.unit
	assert(unit != null)
	if unit == null:
		print("Unit not found at: %s" % card_instance.location)
		goto(neutral)
		return
	
	var ability: CardAbility = card_instance.card.abilities[index]
	assert(ability != null)
	if ability == null:
		print("Invalid ability index: %s" % index)
		goto(neutral)
		return
	
	if ability.effect == null:
		print("Ability has no effect! (index: %s)" % index)
		goto(neutral)
		return
	
	var new_ability_instance := battle_state.ability_perform(battle_state.current_turn, unit.card_instance, index)
	
	wait_for(new_ability_instance.task, activate_ability_finished)

func _process_activate_ability_grace(card_instance: CardInstance, index: int) -> void:
	var ability: CardAbility = card_instance.card.abilities[index]
	assert(ability != null)
	if ability == null:
		print("Invalid ability index: %s" % index)
		goto(neutral)
		return
	
	if ability.effect == null:
		print("Ability has no effect! (index: %s)" % index)
		goto(neutral)
		return
	
	var new_ability_instance := battle_state.ability_perform(battle_state.current_turn, card_instance, index)
	
	wait_for(new_ability_instance.task, activate_ability_finished)

func _process_activate_ability_stella(card_instance: CardInstance, index: int) -> void:
	var ability: CardAbility = card_instance.card.abilities[index]
	assert(ability != null)
	if ability == null:
		print("Invalid ability index: %s" % index)
		goto(neutral)
		return
	
	if ability.effect == null:
		print("Ability has no effect! (index: %s)" % index)
		goto(neutral)
		return
	
	var new_ability_instance := battle_state.ability_perform(battle_state.current_turn, card_instance, index)
	
	wait_for(new_ability_instance.task, activate_ability_finished)


func activate_ability_finished() -> void:
	battle_state.trigger_events_clear()
	goto(neutral)

func process_end_turn(_payload):
	done()

func _require(payload: Dictionary, props: Array[StringName]) -> bool:
	for p in props:
		assert(p in payload)
		if not p in payload:
			print("Invalid payload: %s" % payload)
			return false
	return true

#func process_retreat(_payload):
#	push_error("Not implemented")
#	goto(neutral)
#
#func process_pass(_payload):
#	end_turn()
#
#func end_turn():
#	battle_state.current_turn = ZoneLocation.flip(battle_state.current_turn)
#	run_task(TurnTask.new())
#	done()
