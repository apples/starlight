class_name BattleScene extends Node

@export var card_plane_scene: PackedScene = preload("res://objects/card_plane/card_plane.tscn")

@onready var battle_state: BattleState = $BattleState
@onready var fiber: CardFiber = $BattleState/CardFiber

@onready var player_field: BattleField = $PlayerField
@onready var opponent_field: BattleField = $OpponentField

@onready var player_hand := $PlayerHand
@onready var opponent_hand := $OpponentHand

@onready var player_tokens := $PlayerTokens
@onready var opponent_tokens := $OpponentTokens

@onready var card_preview := $UI/CardPreview

@onready var screen_label_container = %ScreenLabelContainer
@onready var screen_label = %ScreenLabel

@onready var ui = $UI

var screen_layer_stack: Array[BattleScreenLayer] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	reconcile()
	
	fiber.run_task(RootBattleTask.new())
	
	card_preview.visible = false
	

func _process(delta: float):
	fiber.execute_one()
	#reconcile()

## Completely re-syncs the visual state with the BattleState.
## Should only be called on initialization.
func reconcile():
	var player_state := battle_state.get_side_state(ZoneLocation.Side.Player)
	var opponent_state := battle_state.get_side_state(ZoneLocation.Side.Opponent)
	_reconcile_field(player_state, player_field)
	_reconcile_field(opponent_state, opponent_field)
	_reconcile_hand(player_state, player_hand, false)
	_reconcile_hand(opponent_state, opponent_hand, true)
	_reconcile_tokens(player_state, player_tokens)
	_reconcile_tokens(opponent_state, opponent_tokens)

func _reconcile_field(state: BattleSideState, field: BattleField):
	_reconcile_field_row(state.front_row, field.front_row)
	_reconcile_field_row(state.back_row, field.back_row)
	_reconcile_card(field.stella, state.stella)

func _reconcile_field_row(state_row: Array[UnitState], field_row: Array[CardPlane]):
	for i in range(state_row.size()):
		if i >= field_row.size():
			push_error("Too many units in row")
			break
		_reconcile_field_slot(field_row[i], state_row[i])
	for i in range(state_row.size(), field_row.size()):
		_reconcile_field_slot(field_row[i], null)

func _reconcile_field_slot(slot_card_plane: CardPlane, slot_unit: UnitState):
	if slot_unit:
		slot_card_plane.show_card = true
		slot_card_plane.card = slot_unit.card_instance.card
		slot_card_plane.is_tapped = slot_unit.is_tapped
	else:
		slot_card_plane.show_card = false
		slot_card_plane.card = null

func _reconcile_card(slot_card_plane: CardPlane, card_instance: CardInstance):
	if card_instance:
		slot_card_plane.show_card = true
		slot_card_plane.card = card_instance.card
	else:
		slot_card_plane.show_card = false
		slot_card_plane.card = null

func _reconcile_hand(state: BattleSideState, hand: BattleHand, hidden: bool):
	hand.clear()
	
	for i in range(state.hand.size()):
		hand.add_card(state.hand.get_card(i))

func _reconcile_tokens(side_state: BattleSideState, tokens):
	tokens.set_amounts(side_state.token_amounts)

func push_screen(screen_scene, init: Callable = func(a): pass) -> BattleScreenLayer:
	var screen := (
		screen_scene.instantiate() if screen_scene is PackedScene
		else screen_scene) as BattleScreenLayer
	
	print("push_screen: %s (from %s)" % [screen.name, screen_scene])
	
	screen.battle_scene = self
	screen.battle_state = self.battle_state
	
	if screen_layer_stack.size() > 0:
		screen_layer_stack[-1].cover()
	
	screen_layer_stack.append(screen)
	
	if init:
		init.call(screen)
	
	ui.add_child(screen)
	screen.uncover()
	
	return screen

func pop_screen():
	assert(screen_layer_stack.size() > 0)
	if screen_layer_stack.size() == 0:
		return
	
	var screen = screen_layer_stack.pop_back()
	print("pop_screen: %s" % screen.name)
	ui.remove_child(screen)
	screen.queue_free()
	
	if screen_layer_stack.size() > 0:
		screen_layer_stack[-1].uncover()

func set_preview_card(card: Card):
	if not card:
		card_preview.visible = false
		return
	
	card_preview.visible = true
	card_preview.card = card


func get_card_plane(location: ZoneLocation) -> CardPlane:
	var field := player_field
	
	match location.side:
		ZoneLocation.Side.Player:
			field = player_field
		ZoneLocation.Side.Opponent:
			field = opponent_field
	
	var row := field.back_row
	
	match location.zone:
		ZoneLocation.Zone.FrontRow:
			row = field.front_row
		ZoneLocation.Zone.BackRow:
			row = field.back_row
		_:
			assert(false)
			push_error("Not supported")
	
	assert(location.slot >= 0 && location.slot < row.size())
	
	return row[location.slot]



func set_screen_label(str: String):
	screen_label_container.visible = str != ""
	screen_label.text = str
	screen_label.animate()


func get_hand(side: ZoneLocation.Side) -> BattleHand:
	match side:
		ZoneLocation.Side.Player:
			return player_hand
		ZoneLocation.Side.Opponent:
			return opponent_hand
	return null

func get_field(side: ZoneLocation.Side):
	match side:
		ZoneLocation.Side.Player:
			return player_field
		ZoneLocation.Side.Opponent:
			return opponent_field
	return null

func _on_player_agent_message_received(message: BattleAgent.Message):
	var handler := "_handle_%s" % message.get_type()
	if self.has_method(handler):
		self.call(handler, message)


func _handle_card_moved(message: MessageTypes.CardMoved):
	var card_instance := battle_state.get_card_instance(message.uid)
	var card: Card = card_instance.card if card_instance else null
	
	match message.from.tuple():
		[var side, ZoneLocation.Zone.Hand, var slot]:
			get_hand(side).remove_card(slot)
		[_, ZoneLocation.Zone.FrontRow, _]:
			var card_plane := get_card_plane(message.from)
			card_plane.card = null
			card_plane.show_card = false
		[_, ZoneLocation.Zone.BackRow, _]:
			var card_plane := get_card_plane(message.from)
			card_plane.card = null
			card_plane.show_card = false
	
	match message.to.tuple():
		[var side, ZoneLocation.Zone.Hand, var slot]:
			get_hand(side).add_card(card_instance)
		[_, ZoneLocation.Zone.FrontRow, _]:
			var card_plane := get_card_plane(message.to)
			card_plane.card = card
			card_plane.show_card = true
		[_, ZoneLocation.Zone.BackRow, _]:
			var card_plane := get_card_plane(message.to)
			card_plane.card = card
			card_plane.show_card = true


func _handle_unit_tapped_changed(message: MessageTypes.UnitTappedChanged):
	get_card_plane(message.location).is_tapped = message.is_tapped


func _handle_unit_removed(message: MessageTypes.UnitRemoved):
	get_card_plane(message.location).reset()

