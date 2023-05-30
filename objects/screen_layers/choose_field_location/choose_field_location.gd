extends BattleScreenLayer

signal location_picked(location: ZoneLocation)

var allowed_locations: Array[ZoneLocation] = []

@onready var click_target_agent: ClickTargetAgent = $ClickTargetAgent

func _ready():
	pass

func uncover():
	super.uncover()
	
	click_target_agent.set_criteria({
		group_layer_mask = ClickTargetGroup.LAYER_BATTLE,
		target_filter = func (cl: ClickTarget):
			if !cl.location:
				return false
			for allowed in allowed_locations:
				if cl.location.equals(allowed):
					return true
			return false
	})
	
	battle_scene.set_screen_label("Choose Location")
	
	var results := click_target_agent.get_enabled_click_targets()
	
	if results.size() == 0:
		location_picked.emit(null)
		battle_scene.pop_screen()

func _on_click_target_agent_confirmed(click_target):
	battle_scene.pop_screen()
	emit_signal("location_picked", click_target.location)
