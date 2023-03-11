class_name TaskRequestTriggerResponse extends CardTask

var side: ZoneLocation.Side = ZoneLocation.Side.Player
var is_second_priority: bool = false

var _available_triggers: Array[Array] = []

func _init(s: ZoneLocation.Side):
	side = s

func start() -> void:
	# Find possible trigger activations
	
	var side_state := battle_state.get_side_state(side)
	var all_units := side_state.get_all_units()
	
	_available_triggers = []
	
	for unit in all_units:
		var arr: Array = [unit.card_instance.uid]
		if _check_ability(unit.card_instance, unit.card_instance.card.ability1):
			arr.append("ability1")
		if _check_ability(unit.card_instance, unit.card_instance.card.ability2):
			arr.append("ability2")
		if arr.size() > 1:
			_available_triggers.append(arr)
	
	# If no possible triggers, skip response window
	if _available_triggers.size() == 0:
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
	var key: String = trigger_action[1]
	
	assert(key == "ability1" or key == "ability2")
	if key != "ability1" and key != "ability2":
		push_error("Invalid response")
		return done(null, Result.FAILED)
	
	# Find choice in the list
	
	var chosen: Array = []
	for choice in _available_triggers:
		if choice[0] == uid and key in choice:
			chosen = choice
			break
	
	assert(chosen != [])
	if chosen == []:
		push_error("Invalid choice")
		return done(null, Result.FAILED)
	
	
	# Execute trigger
	
	var card_instance: CardInstance = battle_state.all_card_instances[uid]
	var ability: CardAbility = card_instance.card[key]
	
	var ability_instance := battle_state.perform_ability(side, card_instance, ability)
	
	return become(ability_instance.task)


func pass_to_next() -> void:
	# If we're not second priority, pass to opponent
	
	if not is_second_priority:
		var next_task := TaskRequestTriggerResponse.new(ZoneLocation.flip(side))
		next_task.is_second_priority = true
		return become(next_task)
	
	# Otherwise, we are done
	done()

func _check_ability(card_instance: CardInstance, ability: CardAbility) -> bool:
	if not ability:
		return false
	if ability.cost and ability.cost.can_be_paid(battle_state, card_instance, side):
		return true
	return false
