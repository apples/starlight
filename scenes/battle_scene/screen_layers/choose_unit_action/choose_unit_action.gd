extends BattleScreenLayer

@onready var cursor := $CardCursor

var card_instance: BattleState.CardInstance = null
var location: BattleState.ZoneLocation = null

signal action_chosen(action: Dictionary)

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_ACTIONS, func (cl: CursorLocation):
		return true
	)
	
	if results.size() > 0:
		cursor.enabled = true
		cursor.current_cursor_location = results[0]
	else:
		emit_signal("action_chosen", null)
		battle_scene.pop_screen()

func _process(delta: float):
	if Input.is_action_just_pressed("confirm"):
		if cursor.current_cursor_location:
			
			#emit_signal("action_chosen", card_plane.location)
			battle_scene.pop_screen()
