extends BattleAgent

@export var deck: CardDeck = null

@export var battle_scene: BattleScene

@export var turn_input_screen_scene: PackedScene = preload("res://scenes/battle_scene/screen_layers/turn_input/turn_input.tscn")

func get_deck() -> CardDeck:
	if deck: return deck
	return CardDeck.new()

func handle_message(message: Dictionary):
	print("Player got message: %s" % message)
	var handler: StringName = "handle_%s" % message.type
	if self.has_method(handler):
		call(handler, message)

func handle_take_turn(message: Dictionary):
	print("Taking turn")
	print(message)
	
	var screen = battle_scene.push_screen(turn_input_screen_scene)
	var action = await screen.player_action
	
	message.action_future.fulfill(action)
