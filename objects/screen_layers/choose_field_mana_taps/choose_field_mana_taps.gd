extends BattleScreenLayer

signal locations_picked(location: ZoneLocation)

var available_locations: Array[ZoneLocation] = []
var amount: int = 0

var _chosen: Array[ZoneLocation] = []

@onready var click_target_agent: ClickTargetAgent = $ClickTargetAgent

func _ready():
	pass

func uncover():
	super.uncover()
	
	assert(amount > 0, "Required mana tap amount must be greater than zero")
	
	click_target_agent.set_criteria({
		group_layer_mask = ClickTargetGroup.LAYER_BATTLE,
		target_filter = func (cl: ClickTarget):
			if !cl.location:
				return false
			for allowed in available_locations:
				if cl.location.equals(allowed):
					if battle_state.unit_get(cl.location):
						return true
			return false
	})
	
	_update_label()
	
	var results := click_target_agent.get_enabled_click_targets()
	
	if results.size() < amount:
		push_warning("No possible targets")
		locations_picked.emit(null)
		battle_scene.pop_screen()

func _update_label():
	battle_scene.set_screen_label("Choose Mana Source (%s/%s)" % [_chosen.size() / amount])


func _on_click_target_agent_confirmed(click_target):
	_chosen.append(click_target.location)
	click_target.enabled = false
	
	_update_label()
	
	if _chosen.size() >= amount:
		locations_picked.emit(_chosen)
		battle_scene.pop_screen()
	else:
		assert(ClickTargetManager.current_click_target)
