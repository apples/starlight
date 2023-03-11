extends BattleScreenLayer

@onready var cursor: CardCursor = $CardCursor

signal locations_picked(location: ZoneLocation)

var available_locations: Array[ZoneLocation] = []
var amount: int = 0

var _chosen: Array[ZoneLocation] = []

func _ready():
	pass

func uncover():
	super.uncover()
	
	assert(amount > 0, "Required mana tap amount must be greater than zero")
	
	var results := CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		for allowed in available_locations:
			if cl.location.equals(allowed):
				if battle_state.get_unit(cl.location):
					return true
		return false
	)
	
	if results.size() >= amount:
		cursor.enabled = true
		cursor.current_cursor_location = results[0]
	else:
		push_warning("No possible targets")
		locations_picked.emit(null)
		battle_scene.pop_screen()


func _process(delta: float):
	_process_input(delta)


func _process_input(delta: float):
	if Input.is_action_just_pressed("confirm"):
		if cursor.current_cursor_location:
			var card_plane: CardPlane = cursor.current_cursor_location.get_parent()
			_chosen.append(card_plane.location)
			cursor.disable_current()
			
			if _chosen.size() >= amount:
				locations_picked.emit(_chosen)
				battle_scene.pop_screen()
			else:
				assert(cursor.current_cursor_location)

