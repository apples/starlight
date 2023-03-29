extends BattleScreenLayer

signal location_picked(location: ZoneLocation)

var allowed_locations: Array[ZoneLocation] = []

var target_from

@onready var arrow_path = $ArrowPath

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CardCursor.set_criteria(CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		for allowed in allowed_locations:
			if cl.location.equals(allowed):
				if battle_state.unit_get(cl.location):
					return true
		return false
	)
	
	battle_scene.set_screen_label("Choose Target")
	
	if results.size() == 0:
		push_warning("No possible targets")
		emit_signal("location_picked", null)
		battle_scene.pop_screen()
	else:
		results[0].make_current()
		
		if target_from is ZoneLocation:
			var target := battle_scene.get_card_plane(target_from)
			arrow_path.visible = true
			arrow_path.start = target.global_position
		else:
			arrow_path.visible = false


func _on_card_cursor_agent_confirmed(cursor_location):
	battle_scene.pop_screen()
	var card_plane: CardPlane = cursor_location.get_parent()
	location_picked.emit(card_plane.location)


func _on_card_cursor_agent_cursor_location_changed(cursor_location):
	if cursor_location:
		arrow_path.end = cursor_location.global_position


func _on_card_cursor_agent_cancelled():
	location_picked.emit(null)
