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

@onready var player_stella = $PlayerStella
@onready var opponent_stella = $OpponentStella

@onready var card_preview := $UI/CardPreview

var screen_layer_stack: Array[BattleScreenLayer] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	fiber.run_task(RootBattleTask.new())
	
	assert(player_field.front_row.size() == opponent_field.front_row.size())
	for i in range(player_field.front_row.size()):
		var p := player_field.front_row[i].cursor_location
		var o := opponent_field.front_row[opponent_field.front_row.size() - i - 1].cursor_location
		p.up = o
		o.down = p
	
	card_preview.visible = false

func _process(delta: float):
	fiber.execute_one()
	reconcile()

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

func _reconcile_hand(state: BattleSideState, hand: Node3D, hidden: bool):
	for i in range(state.hand.size()):
		var card_plane: CardPlane = null
		if i < hand.get_child_count():
			card_plane = hand.get_child(i)
		else:
			card_plane = card_plane_scene.instantiate()
			card_plane.cursor_layers = \
				CursorLocation.LAYER_BATTLE | \
				CursorLocation.LAYER_HAND | \
				(CursorLocation.LAYER_PLAYER if hand == player_hand else CursorLocation.LAYER_OPPONENT)
			hand.add_child(card_plane)
		card_plane.card = state.hand[i].card if not hidden else null
		card_plane.location = ZoneLocation.new(state.side, ZoneLocation.Zone.Hand, i)
		var cursor_location = card_plane.cursor_location
		if i > 0:
			var left_slot := hand.get_child(i - 1) as CardPlane
			left_slot.cursor_location.right = cursor_location
			cursor_location.left = left_slot.cursor_location
		else:
			cursor_location.left = null
		if i == state.hand.size() - 1:
			cursor_location.right = null
		if state.side == ZoneLocation.Side.Player:
			cursor_location.up = player_field.back_row[1].cursor_location
	
	if hand.get_child_count() > 0 and state.side == ZoneLocation.Side.Player:
		for card_plane in player_field.back_row:
			var cl := card_plane.cursor_location
			cl.down = hand.get_child((hand.get_child_count() - 1) / 2).cursor_location
	
	for i in range(state.hand.size(), hand.get_child_count()):
		hand.get_child(i).queue_free()

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
	
	add_child(screen)
	screen.uncover()
	
	return screen

func pop_screen():
	assert(screen_layer_stack.size() > 0)
	if screen_layer_stack.size() == 0:
		return
	
	var screen = screen_layer_stack.pop_back()
	print("pop_screen: %s" % screen.name)
	remove_child(screen)
	screen.queue_free()
	
	if screen_layer_stack.size() > 0:
		screen_layer_stack[-1].uncover()

func set_preview_card(card_instance: CardInstance):
	if not card_instance:
		card_preview.visible = false
		return
	
	card_preview.visible = true
	card_preview.card = card_instance.card


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
