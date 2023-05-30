class_name TaskRequestTriggerResponse extends CardTask

var side: ZoneLocation.Side = ZoneLocation.Side.Player
var is_second_priority: bool = false

var _available_triggers: Array[Dictionary] = []

func _init(s: ZoneLocation.Side):
	side = s

func start() -> void:
	
	print("request_trigger_response: %s" % [ZoneLocation.Side.find_key(side)])
	
	# Find possible trigger activations
	
	var side_state := battle_state.get_side_state(side)
	var all_units := side_state.get_all_units()
	
	_available_triggers = []
	
	for unit in all_units:
		var d: Dictionary = { card_uid = unit.card_instance.uid, available_trigger_abilities = [] }
		for i in range(unit.card_instance.card.abilities.size()):
			if _check_ability(unit.card_instance, i):
				d.available_trigger_abilities.append(i)
		if not d.available_trigger_abilities.is_empty():
			_available_triggers.append(d)
	
	# If no possible triggers, skip response window
	if _available_triggers.size() == 0:
		print("request_trigger_response: no valid triggers")
		return goto(pass_to_next)
	
	var action_future := Future.new()
	battle_state.send_message_to(side, MessageTypes.RequestResponse.new({
		action_future = action_future,
		available_triggers = _available_triggers,
	}))
	wait_for_future(action_future, action_chosen)


func action_chosen(trigger_action: Array) -> void:
	# Check for pass
	
	if trigger_action.size() == 0:
		return goto(pass_to_next)
	
	# Validate parameters
	
	assert(trigger_action.size() == 2)
	if trigger_action.size() > 2:
		push_error("Invalid response: unexpected tuple size")
		return done(null, Result.FAILED)
	
	var uid: int = trigger_action[0]
	
	assert(uid in battle_state.all_card_instances)
	if not uid in battle_state.all_card_instances:
		push_error("Invalid response")
		return done(null, Result.FAILED)
	
	var card_instance: CardInstance = battle_state.all_card_instances[uid]
	
	var ability_index: int = trigger_action[1]
	assert(ability_index >= 0)
	assert(ability_index < card_instance.card.abilities.size())
	if not (ability_index >= 0 and ability_index < card_instance.card.abilities.size()):
		push_error("Invalid response")
		return done(null, Result.FAILED)
	
	# Find choice in the list
	
	var chosen: Dictionary
	for choice in _available_triggers:
		if choice.card_uid == uid and ability_index in choice.available_trigger_abilities:
			chosen = choice
			break
	
	assert(chosen != {})
	if chosen == {}:
		push_error("Invalid choice, this is a bug!")
		return done(null, Result.FAILED)
	
	# Execute trigger
	
	var new_ability_instance := battle_state.ability_perform(side, card_instance, ability_index)
	
	return become(new_ability_instance.task)


func pass_to_next() -> void:
	# If we're not second priority, pass to opponent
	
	if not is_second_priority:
		var next_task := TaskRequestTriggerResponse.new(ZoneLocation.flip(side))
		next_task.is_second_priority = true
		return become(next_task)
	
	# Otherwise, we are done
	done()

func _check_ability(card_instance: CardInstance, ability_index: int) -> bool:
	assert(ability_index >= 0)
	assert(ability_index < card_instance.card.abilities.size())
	
	var ability: CardAbility = card_instance.card.abilities[ability_index]
	assert(ability)
	
	print("_check_ability(%s)" % [ability])
	
	if not ability.type == CardAbility.CardAbilityType.TRIGGER:
		print("    not a trigger")
		return false
	if ability.cost and not ability.cost.can_be_paid(battle_state, card_instance, ability_index, side):
		print("    cannot pay cost")
		return false
	if ability.trigger and not ability.trigger.can_activate(battle_state, card_instance, ability_index, side):
		print("    cannot be activated")
		return false
	
	print("    check passed")
	return true
