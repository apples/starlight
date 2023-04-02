extends BattleAgent

@export var deck: CardDeck = null

@export var battle_scene: BattleScene

@export var turn_input_screen_scene: PackedScene = preload("res://objects/screen_layers/turn_input/turn_input.tscn")
@export var choose_target_screen_scene: PackedScene = preload("res://objects/screen_layers/choose_field_unit/choose_field_unit.tscn")
@export var choose_field_mana_taps: PackedScene = preload("res://objects/screen_layers/choose_field_mana_taps/choose_field_mana_taps.tscn")
@export var choose_card_ability_scene: PackedScene = preload("res://objects/screen_layers/choose_card_ability/choose_card_ability.tscn")
@export var choose_field_unit: PackedScene = preload("res://objects/screen_layers/choose_field_unit/choose_field_unit.tscn")

signal message_received(message: BattleAgent.Message)

func get_deck() -> CardDeck:
	if deck: return deck
	return CardDeck.new()

func handle_message(message: BattleAgent.Message):
	print("player_agent got message: %s" % message)
	message_received.emit(message)
	var handler: StringName = "handle_%s" % message.type
	if self.has_method(handler):
		print("player_agent message handler: %s" % handler)
		call(handler, message)

func handle_take_turn(message: MessageTypes.TakeTurn):
	var screen = battle_scene.push_screen(turn_input_screen_scene, func (screen):
		screen.available_abilities = message.available_abilities
		screen.available_summons = message.available_summons)
	var action = await screen.player_action
	
	message.action_future.fulfill(action)

func handle_choose_target(message: MessageTypes.ChooseTarget):
	var screen = battle_scene.push_screen(choose_target_screen_scene, func (screen):
		screen.allowed_locations = message.allowed_locations
		screen.target_from = message.source_location
		var where: ZoneLocation = await screen.location_picked
		message.future.fulfill(where)
	)

func handle_request_mana_taps(message: MessageTypes.RequestManaTaps):
	var screen = battle_scene.push_screen(choose_field_mana_taps, func (screen):
		screen.available_locations = message.available_locations
		screen.amount = message.amount
		var where: Array[ZoneLocation] = await screen.locations_picked
		message.action_future.fulfill(where)
	)

func handle_request_response(message: MessageTypes.RequestResponse):
	var screen = battle_scene.push_screen(choose_field_unit, func (screen):
		var available_locations: Array[ZoneLocation] = []
		for trigger in message.available_triggers:
			var card_uid: int = trigger[0]
			var card: CardInstance = battle_state.all_card_instances[card_uid]
			assert(card)
			available_locations.append(card.location)
		screen.allowed_locations = available_locations
		var where: ZoneLocation = await screen.location_picked
		_request_response_choose_ability(message, where)
	)

func _request_response_choose_ability(message: MessageTypes.RequestResponse, where: ZoneLocation):
	if not where:
		message.action_future.fulfill([])
		return
	
	var card_instance := battle_state.get_card_at(where)
	
	# Find trigger info index
	
	var trigger_index := -1
	for i in range(message.available_triggers.size()):
		if message.available_triggers[i][0] == card_instance.uid:
			trigger_index = i
			break
	
	assert(trigger_index != -1)
	if trigger_index == -1:
		message.action_future.fulfill([])
	
	var trigger := message.available_triggers[trigger_index]
	
	battle_scene.push_screen(choose_card_ability_scene, func (screen):
		screen.card_instance = card_instance
		screen.allowed_ability_types.append_array([
			CardAbility.CardAbilityType.TRIGGER,
		])
		screen.allowed_ability_indices = []
		for i in range(1, trigger.size()):
			screen.allowed_ability_indices.append(trigger[i])
		var ci_idx = await screen.ability_chosen
		assert(ci_idx.size() == 2)
		var ability_index: int = ci_idx[1]
		if ability_index == -1:
			handle_request_response(message)
			return
		assert(ability_index in screen.allowed_ability_indices)
		message.action_future.fulfill([trigger[0], ability_index])
	)

func handle_unit_damaged(message: MessageTypes.UnitDamaged):
	var card_plane := battle_scene.get_card_plane(message.location)
	card_plane.toast("-%s" % message.amount)
