extends BattleAgent

@export var deck: CardDeck = null

@export var battle_scene: BattleScene

@export var turn_input_screen_scene: PackedScene = preload("res://objects/screen_layers/turn_input/turn_input.tscn")
@export var choose_target_screen_scene: PackedScene = preload("res://objects/screen_layers/choose_field_unit/choose_field_unit.tscn")

func get_deck() -> CardDeck:
	if deck: return deck
	return CardDeck.new()

func handle_message(message: BattleAgent.Message):
	print("Player got message: %s" % message)
	var handler: StringName = "handle_%s" % message.type
	if self.has_method(handler):
		call(handler, message)

func handle_take_turn(message: MessageTypes.TakeTurn):
	print("Taking turn")
	print(message)
	
	var screen = battle_scene.push_screen(turn_input_screen_scene)
	var action = await screen.player_action
	
	message.action_future.fulfill(action)

func handle_choose_target(message: MessageTypes.ChooseTarget):
	print("Choosing target")
	print(message)
	
	var screen = battle_scene.push_screen(choose_target_screen_scene, func (screen):
		screen.allowed_locations = message.allowed_locations
		print(screen)
	)
	var where: ZoneLocation = await screen.location_picked
	
	message.future.fulfill(where)
