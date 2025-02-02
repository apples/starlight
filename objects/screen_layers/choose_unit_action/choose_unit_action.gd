extends BattleScreenLayer

@onready var control_root := %ControlRoot

var card_plane: CardPlane = null

signal action_chosen(action: Dictionary)

@onready var click_target_agent: ClickTargetAgent = $ClickTargetAgent

func uncover():
	super.uncover()
	
	control_root.global_position = get_viewport().get_camera_3d().unproject_position(card_plane.action_root.global_position)
	
	click_target_agent.set_criteria({ group_layer_mask = ClickTargetGroup.LAYER_ACTIONS })
	
	battle_scene.set_screen_label("Choose Unit Action")
	
	var results := click_target_agent.get_enabled_click_targets()
	
	if results.size() == 0:
		emit_signal("action_chosen", null)
		remove_screen()
	else:
		results[0].make_current()


func _on_click_target_agent_confirmed(click_target):
	assert(is_ancestor_of(click_target))
	remove_screen()
	emit_signal("action_chosen", {
		type = click_target.custom_tag,
		where = card_plane.location})


func _on_click_target_agent_cancelled():
	remove_screen()
	action_chosen.emit({})
