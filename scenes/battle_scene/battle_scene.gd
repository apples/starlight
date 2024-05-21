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
@onready var fiber_debug: PanelContainer = %FiberDebug

var screen_layer_stack: Array[BattleScreenLayer] = []

var _is_debugging: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	reconcile()
	
	fiber.run_task(RootBattleTask.new())
	
	card_preview.visible = false
	

func _process(delta: float):
	if Input.is_action_just_pressed("fiber_debug_toggle"):
		_is_debugging = not _is_debugging
		fiber_debug.visible = _is_debugging
	
	if _is_debugging:
		if Input.is_action_just_pressed("fiber_debug_step"):
			fiber.execute_one()
	else:
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
	_reconcile_card(field.rulecard, state.rulecard)
	field.set_grace_count(state.graces.size())

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
	var hand := player_hand
	
	match location.side:
		ZoneLocation.Side.Player:
			field = player_field
			hand = player_hand
		ZoneLocation.Side.Opponent:
			field = opponent_field
			hand = opponent_hand
	
	match location.zone:
		ZoneLocation.Zone.FrontRow:
			assert(location.slot >= 0 && location.slot < field.front_row.size())
			return field.front_row[location.slot]
		ZoneLocation.Zone.BackRow:
			assert(location.slot >= 0 && location.slot < field.back_row.size())
			return field.back_row[location.slot]
		ZoneLocation.Zone.Hand:
			var row: Array[CardPlane] = []
			for c in hand.group.get_children():
				if c is CardPlane:
					row.append(c)
			assert(location.slot >= 0 && location.slot < row.size())
			return row[location.slot]
		ZoneLocation.Zone.Rulecard:
			assert(location.slot == -1)
			return field.rulecard
		_:
			push_error("Location %s cannot have a card plane" % [location])
			return null



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
	
	print("<<< GOT MESADSADE >>> ", message)
	
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
		[var side, ZoneLocation.Zone.Grace, _]:
			get_field(side).set_grace_count(battle_state.get_side_state(side).graces.size())
	
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
		[var side, ZoneLocation.Zone.Grace, _]:
			get_field(side).set_grace_count(battle_state.get_side_state(side).graces.size())
	


func _handle_unit_tapped_changed(message: MessageTypes.UnitTappedChanged):
	get_card_plane(message.location).is_tapped = message.is_tapped


func _handle_unit_removed(message: MessageTypes.UnitRemoved):
	get_card_plane(message.location).reset()

