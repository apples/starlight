extends BattleAgent

@export var deck: CardDeck = null

@export var battle_scene: BattleScene

@export var turn_input_screen_scene: PackedScene = preload("res://objects/screen_layers/turn_input/turn_input.tscn")
@export var choose_target_screen_scene: PackedScene = preload("res://objects/screen_layers/choose_field_unit/choose_field_unit.tscn")
@export var choose_field_mana_taps: PackedScene = preload("res://objects/screen_layers/choose_field_mana_taps/choose_field_mana_taps.tscn")

func get_deck() -> CardDeck:
	if deck: return deck
	return CardDeck.new()

func handle_message(message: BattleAgent.Message):
	print("player_agent got message: %s" % message)
	var handler: StringName = "handle_%s" % message.type
	if self.has_method(handler):
		print("player_agent message handler: %s" % handler)
		call(handler, message)

func handle_take_turn(message: MessageTypes.TakeTurn):
	var screen = battle_scene.push_screen(turn_input_screen_scene)
	var action = await screen.player_action
	
	message.action_future.fulfill(action)

func handle_choose_target(message: MessageTypes.ChooseTarget):
	var screen = battle_scene.push_screen(choose_target_screen_scene, func (screen):
		screen.allowed_locations = message.allowed_locations
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
	message.action_future.fulfill([])
