extends BattleScreenLayer

@onready var cursor := $CardCursor

signal location_picked(location: BattleState.ZoneLocation)

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
		if !cl.location:
			return false
		match cl.location.tuple():
			[BattleState.Side.Player, BattleState.Zone.FrontRow, _], [BattleState.Side.Player, BattleState.Zone.BackRow, _]:
				var unit := battle_state.get_unit_at(cl.location)
				return unit == null
		return false
	)
	
	if results.size() > 0:
		cursor.enabled = true
		cursor.current_cursor_location = results[0]
	else:
		emit_signal("location_picked", null)
		battle_scene.pop_screen()

func _process(delta: float):
	_process_input(delta)

func _process_input(delta: float):
	if Input.is_action_just_pressed("confirm"):
		if cursor.current_cursor_location:
			battle_scene.pop_screen()
			var card_plane: CardPlane = cursor.current_cursor_location.get_parent()
			emit_signal("location_picked", card_plane.location)
