extends BattleScreenLayer

signal location_picked(location: ZoneLocation)

var allowed_locations: Array[ZoneLocation] = []

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := ClickTargetManager.set_criteria(ClickTargetGroup.LAYER_BATTLE, func (cl: ClickTarget):
		if !cl.location:
			return false
		for allowed in allowed_locations:
			if cl.location.equals(allowed):
				return true
		return false
	)
	
	battle_scene.set_screen_label("Choose Location")
	
	if results.size() == 0:
		location_picked.emit(null)
		battle_scene.pop_screen()

func _on_click_target_agent_confirmed(click_target):
	battle_scene.pop_screen()
	emit_signal("location_picked", click_target.location)
