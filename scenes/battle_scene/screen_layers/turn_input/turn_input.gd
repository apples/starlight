extends BattleScreenLayer

@onready var cursor := $CardCursor

@export var choose_field_location_scene: PackedScene = preload("res://scenes/battle_scene/screen_layers/choose_field_location/choose_field_location.tscn")

var current_cursor_location: CursorLocation = null

signal player_action(action: Dictionary)

func _process(delta: float):
	_process_input(delta)

func uncover():
	super.uncover()
	
	CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		return true
	)

func _process_input(delta: float):
	var nav_dir: StringName = StringName()
	
	if Input.is_action_just_pressed("up"):
		nav_dir = "up"
	elif Input.is_action_just_pressed("down"):
		nav_dir = "down"
	elif Input.is_action_just_pressed("left"):
		nav_dir = "left"
	elif Input.is_action_just_pressed("right"):
		nav_dir = "right"
	
	if nav_dir:
		if !current_cursor_location:
			current_cursor_location = CursorLocation.find_location(get_tree(), BattleState.ZoneLocation.new(BattleState.Side.Player, BattleState.Zone.Hand, 0), CursorLocation.LAYER_BATTLE)
			if !current_cursor_location:
				current_cursor_location = CursorLocation.find_location(get_tree(), BattleState.ZoneLocation.new(BattleState.Side.Player, BattleState.Zone.BackRow, 1), CursorLocation.LAYER_BATTLE)
		else:
			var next := current_cursor_location.navigate(nav_dir)
			if next:
				current_cursor_location = next
			else:
				# TODO: play bonk sfx
				pass
	
	if current_cursor_location:
		cursor.visible = true
		cursor.global_transform = current_cursor_location.global_transform
	else:
		cursor.visible = false
	
	if Input.is_action_just_pressed("confirm"):
		if current_cursor_location:
			var card_plane: CardPlane = current_cursor_location.get_parent()
			match card_plane.location.tuple():
				[BattleState.Side.Player, BattleState.Zone.Hand, var idx]:
					var card_instance := battle_state.player.hand[idx]
					match card_instance.card.kind:
						Card.Kind.UNIT:
							_choose_summon_location(card_instance)

func _choose_summon_location(card_instance: BattleState.CardInstance):
	var screen := battle_scene.push_screen(choose_field_location_scene)
	
	var location = await screen.location_picked
	
	if location:
		emit_signal("player_action", { type = "play_unit", card = card_instance, where = location })
		battle_scene.pop_screen()
