extends BattleScreenLayer

@onready var cursor := $ActionCursor
@onready var control_root := %ControlRoot
@onready var ability_control := %Ability
@onready var retreat_control := %Retreat

var card_plane: CardPlane = null

signal action_chosen(action: Dictionary)

func uncover():
	super.uncover()
	
	control_root.global_position = get_viewport().get_camera_3d().unproject_position(card_plane.action_root.global_position)
	
	var results := CursorLocation.filter_enable(
		get_tree(), CursorLocation.LAYER_ACTIONS, func (cl: CursorLocation):
		return true
	)
	
	if results.size() > 0:
		cursor.enabled = true
		cursor.current_cursor_location = results[0]
	else:
		emit_signal("action_chosen", null)
		remove_screen()

func _process(delta: float):
	if Input.is_action_just_pressed("confirm"):
		if cursor.current_cursor_location:
			remove_screen()
			emit_signal("action_chosen", {
				type = cursor.current_cursor_location.custom_tag,
				where = card_plane.location})
		else:
			remove_screen()
			emit_signal("action_chosen", null)
