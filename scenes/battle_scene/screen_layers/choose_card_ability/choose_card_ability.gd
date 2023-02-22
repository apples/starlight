extends BattleScreenLayer

@onready var cursor := $Cursor

var card_instance: BattleState.CardInstance = null
var allowed_ability_types: Array[CardAbility.CardAbilityType] = []

signal ability_chosen(card_instance: BattleState.CardInstance, index: int)

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_CARD_ABILITIES, func (cl: CursorLocation):
		assert(cl.custom_tag.begins_with("ability_"))
		var key := "ability%s" % cl.custom_tag.trim_prefix("ability_")
		return (card_instance.card[key] as CardAbility).type in allowed_ability_types
	)
	
	if results.size() > 0:
		cursor.enabled = true
		cursor.current_cursor_location = results[0]
		battle_scene.set_preview_card(card_instance)
	else:
		emit_signal("location_picked", null)
		battle_scene.pop_screen()

func _process(delta: float):
	_process_input(delta)

func _process_input(delta: float):
	if Input.is_action_just_pressed("confirm"):
		if cursor.current_cursor_location:
			assert(cursor.current_cursor_location.custom_tag.begins_with("ability_"))
			var idx := int(cursor.current_cursor_location.custom_tag.trim_prefix("ability_"))
			assert("ability%s" % idx in card_instance.card)
			emit_signal("ability_chosen", card_instance, idx)
			battle_scene.pop_screen()
