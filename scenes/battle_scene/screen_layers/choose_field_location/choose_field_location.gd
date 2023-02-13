extends BattleScreenLayer

@onready var cursor := $CardCursor

var current_cursor_location: CursorLocation = null

signal location_picked(location: BattleState.ZoneLocation)

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		print(cl.location)
		match cl.location.tuple():
			[BattleState.Side.Player, BattleState.Zone.FrontRow, _], [BattleState.Side.Player, BattleState.Zone.BackRow, _]:
				print("mat")
				var unit := battle_state.get_unit_at(cl.location)
				print(unit)
				return unit == null
		return false
	)
	
	print(results)
	
	if results.size() > 0:
		current_cursor_location = results[0]
	else:
		emit_signal("location_picked", null)
		battle_scene.pop_screen()
		print("byas")

func _process(delta: float):
	_process_input(delta)

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
			emit_signal("location_picked", card_plane.location)
			battle_scene.pop_screen()
