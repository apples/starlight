extends BattleAgent


@export var deck: CardDeck = null

func get_deck() -> CardDeck:
	if deck: return deck
	return CardDeck.new()

func handle_message(message: BattleAgent.Message):
	print("dummy_agent got message: %s" % message)
	var handler: StringName = "handle_%s" % message.type
	if self.has_method(handler):
		print("dummy_agent message handler: %s" % handler)
		call(handler, message)

func handle_take_turn(message: MessageTypes.TakeTurn):
	if message.available_summons.size() > 0:
		var uid = message.available_summons.pick_random()
		message.action_future.fulfill({ type = "play_unit", uid = uid })
		return
	
	if message.available_abilities.size() > 0:
		var uid = message.available_abilities.keys().pick_random()
		var idx = message.available_abilities[uid].pick_random()
		message.action_future.fulfill({ type = "activate_ability", uid = uid, ability_index = idx })
		return
	
	message.action_future.fulfill({ type = "end_turn" })

func handle_choose_target(message: MessageTypes.ChooseTarget):
	message.future.fulfill(message.allowed_locations.pick_random())

func handle_request_mana_taps(message: MessageTypes.RequestManaTaps):
	var locations := message.available_locations.duplicate()
	locations.shuffle()
	
	var amount := message.amount
	
	var chosen: Array[ZoneLocation] = []
	
	while amount > 0:
		var i = randi_range(0, locations.size() - 1)
		chosen.append(locations[i])
		locations.remove_at(i)
		amount -= 1
	
	message.action_future.fulfill(chosen)

func handle_request_response(message: MessageTypes.RequestResponse):
	var trigger: Dictionary = message.available_triggers.pick_random()
	
	var ability: int = trigger.available_trigger_abilities.pick_random()
	
	message.action_future.fulfill([trigger[0], ability])

func handle_choose_field_location(message: MessageTypes.ChooseFieldLocation):
	message.future.fulfill(message.allowed_locations.pick_random())
