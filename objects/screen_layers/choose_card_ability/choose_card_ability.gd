extends BattleScreenLayer

var card_instance: CardInstance = null
var allowed_ability_types: Array[CardAbility.CardAbilityType] = []
var allowed_ability_indices: Variant = null

signal ability_chosen(card_instance: CardInstance, index: int)

@onready var click_target_agent: ClickTargetAgent = $ClickTargetAgent

func _ready():
	pass

func uncover():
	super.uncover()
	
	battle_scene.set_preview_card(card_instance.card)
	
	click_target_agent.set_criteria({
		group_layer_mask = ClickTargetGroup.LAYER_CARD_ABILITIES,
		target_filter = func (cl: ClickTarget):
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
	})
	
	battle_scene.set_screen_label("Choose Ability to Activate")
	
	var results := click_target_agent.get_enabled_click_targets()
	
	if results.size() > 0:
		results[0].make_current()
	else:
		print("choose_card_ability.gd: No available abilities on card.")
		battle_scene.pop_screen()
		ability_chosen.emit(null, -1)


func _on_click_target_agent_confirmed(click_target):
	assert(click_target.custom_tag.begins_with("ability"))
	var idx := int(click_target.custom_tag.trim_prefix("ability"))
	assert(idx >= 0)
	assert(idx < card_instance.card.abilities.size())
	
	battle_scene.pop_screen()
	ability_chosen.emit(card_instance, idx)


func _on_click_target_agent_cancelled():
	battle_scene.pop_screen()
	ability_chosen.emit(null, -1)
