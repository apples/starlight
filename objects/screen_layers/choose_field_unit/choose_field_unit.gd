extends BattleScreenLayer

signal location_picked(location: ZoneLocation)

var allowed_locations: Array[ZoneLocation] = []

var target_from

@onready var arrow_path = $ArrowPath

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := ClickTargetManager.set_criteria(ClickTargetGroup.LAYER_BATTLE, func (cl: ClickTarget):
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


func _on_click_target_agent_confirmed(click_target):
	battle_scene.pop_screen()
	var card_plane: CardPlane = click_target.get_parent()
	location_picked.emit(card_plane.location)


func _on_click_target_agent_click_target_changed(click_target):
	if click_target:
		arrow_path.end = click_target.global_position


func _on_click_target_agent_cancelled():
	location_picked.emit(null)
