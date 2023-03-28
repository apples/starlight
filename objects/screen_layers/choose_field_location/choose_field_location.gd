extends BattleScreenLayer

signal location_picked(location: ZoneLocation)

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CardCursor.set_criteria(CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		match cl.location.tuple():
			[ZoneLocation.Side.Player, ZoneLocation.Zone.FrontRow, _],\
			[ZoneLocation.Side.Player, ZoneLocation.Zone.BackRow, _]:
				var unit := battle_state.get_unit(cl.location)
				return unit == null
		return false
	)
	
	battle_scene.set_screen_label("Choose Location")
	
	if results.size() == 0:
		emit_signal("location_picked", null)
		battle_scene.pop_screen()

func _on_card_cursor_agent_confirmed(cursor_location):
	battle_scene.pop_screen()
	emit_signal("location_picked", cursor_location.location)
