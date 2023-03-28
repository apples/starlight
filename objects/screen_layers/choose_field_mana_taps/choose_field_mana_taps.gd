extends BattleScreenLayer

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
	
	if results.size() < amount:
		push_warning("No possible targets")
		locations_picked.emit(null)
		battle_scene.pop_screen()



func _on_card_cursor_agent_confirmed(cursor_location):
	_chosen.append(cursor_location.location)
	cursor_location.enabled = false
	
	if _chosen.size() >= amount:
		locations_picked.emit(_chosen)
		battle_scene.pop_screen()
	else:
		assert(CardCursor.current_cursor_location)
