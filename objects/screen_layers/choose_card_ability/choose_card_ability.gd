extends BattleScreenLayer

@onready var cursor := $Cursor

var card_instance: CardInstance = null
var allowed_ability_types: Array[CardAbility.CardAbilityType] = []
var allowed_ability_indices: Variant = null

signal ability_chosen(card_instance: CardInstance, index: int)

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_CARD_ABILITIES, func (cl: CursorLocation):
		# Get index from cursor location
		
		assert(cl.custom_tag.begins_with("ability"))
		var index := int(cl.custom_tag.trim_prefix("ability"))
		assert(index == 0 || index == 1)
		
		# Make sure index is allowed
		
		if allowed_ability_indices != null:
			var _allowed_ability_indices := allowed_ability_indices as Array
			if not index in _allowed_ability_indices:
				return false
		
		# Check ability type
		
		var card_ability := card_instance.card.get_ability(index)
		if not card_ability:
			return false
		if not card_ability.type in allowed_ability_types:
			return false
		
		return true
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
			assert(cursor.current_cursor_location.custom_tag.begins_with("ability"))
			var idx := int(cursor.current_cursor_location.custom_tag.trim_prefix("ability"))
			assert(idx == 0 || idx == 1)
			ability_chosen.emit(card_instance, idx)
			battle_scene.pop_screen()
