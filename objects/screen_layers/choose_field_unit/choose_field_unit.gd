extends BattleScreenLayer

signal location_picked(location: ZoneLocation)

var allowed_locations: Array[ZoneLocation] = []

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CardCursor.set_criteria(CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		for allowed in allowed_locations:
			if cl.location.equals(allowed):
				if battle_state.get_unit(cl.location):
					return true
		return false
	)
	
	battle_scene.set_screen_label("Choose Target")
	
	if results.size() == 0:
		push_warning("No possible targets")
		emit_signal("location_picked", null)
		battle_scene.pop_screen()


func _on_card_cursor_agent_confirmed(cursor_location):
	battle_scene.pop_screen()
	var card_plane: CardPlane = cursor_location.get_parent()
	emit_signal("location_picked", card_plane.location)
