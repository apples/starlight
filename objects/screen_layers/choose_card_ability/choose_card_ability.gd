extends BattleScreenLayer

var card_instance: CardInstance = null
var allowed_ability_types: Array[CardAbility.CardAbilityType] = []
var allowed_ability_indices: Variant = null

signal ability_chosen(card_instance: CardInstance, index: int)

func _ready():
	pass

func uncover():
	super.uncover()
	
	var results := CardCursor.set_criteria(CursorLocation.LAYER_CARD_ABILITIES, func (cl: CursorLocation):
		# Get index from cursor location
		
		assert(cl.custom_tag.begins_with("ability"))
		var index := int(cl.custom_tag.trim_prefix("ability"))
		assert(index >= 0)
		assert(index < card_instance.card.abilities.size())
		
		# Make sure index is allowed
		
		if allowed_ability_indices != null:
			var _allowed_ability_indices := allowed_ability_indices as Array
			if not index in _allowed_ability_indices:
				return false
		
		# Check ability type
		
		var card_ability := card_instance.card.abilities[index]
		assert(card_ability)
		
		if not card_ability.type in allowed_ability_types:
			return false
		
		return true
	)
	
	battle_scene.set_screen_label("Choose Ability to Activate")
	
	if results.size() > 0:
		CardCursor.current_cursor_location = results[0]
		battle_scene.set_preview_card(card_instance.card)
	else:
		ability_chosen.emit(null, -1)
		battle_scene.pop_screen()


func _on_card_cursor_agent_confirmed(cursor_location):
	assert(cursor_location.custom_tag.begins_with("ability"))
	var idx := int(cursor_location.custom_tag.trim_prefix("ability"))
	assert(idx >= 0)
	assert(idx < card_instance.card.abilities.size())
	
	ability_chosen.emit(card_instance, idx)
	battle_scene.pop_screen()


func _on_card_cursor_agent_cancelled():
	ability_chosen.emit(null, -1)
	battle_scene.pop_screen()
