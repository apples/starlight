extends BattleScreenLayer

@onready var control_root := %ControlRoot

var card_plane: CardPlane = null

signal action_chosen(action: Dictionary)

func uncover():
	super.uncover()
	
	control_root.global_position = get_viewport().get_camera_3d().unproject_position(card_plane.action_root.global_position)
	
	var results := CardCursor.set_criteria(
		CursorLocation.LAYER_ACTIONS, func (cl: CursorLocation):
		return true
	)
	
	battle_scene.set_screen_label("Choose Unit Action")
	
	if results.size() == 0:
		emit_signal("action_chosen", null)
		remove_screen()
	else:
		results[0].make_current()
	


func _on_card_cursor_agent_confirmed(cursor_location: CursorLocation):
	assert(is_ancestor_of(cursor_location))
	remove_screen()
	emit_signal("action_chosen", {
		type = cursor_location.custom_tag,
		where = card_plane.location})


func _on_card_cursor_agent_cancelled():
	remove_screen()
	emit_signal("action_chosen", null)

