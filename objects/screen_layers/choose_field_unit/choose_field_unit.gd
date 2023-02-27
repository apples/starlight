extends BattleScreenLayer

@onready var cursor := $CardCursor

signal location_picked(location: ZoneLocation)

var allowed_locations: Array[ZoneLocation] = []

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		for allowed in allowed_locations:
			if cl.location.equals(allowed):
				return true
		return false
	)
	
	if results.size() > 0:
		cursor.enabled = true
		cursor.current_cursor_location = results[0]
	else:
		push_warning("No possible targets")
		emit_signal("location_picked", null)
		battle_scene.pop_screen()

func _process(delta: float):
	_process_input(delta)

func _process_input(delta: float):
	if Input.is_action_just_pressed("confirm"):
		if cursor.current_cursor_location:
			battle_scene.pop_screen()
			var card_plane: CardPlane = cursor.current_cursor_location.get_parent()
			emit_signal("location_picked", card_plane.location)
