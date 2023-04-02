extends BattleScreenLayer

@export var choose_field_location_scene: PackedScene = preload("res://objects/screen_layers/choose_field_location/choose_field_location.tscn")
@export var choose_unit_action_scene: PackedScene = preload("res://objects/screen_layers/choose_unit_action/choose_unit_action.tscn")
@export var choose_card_ability_scene: PackedScene = preload("res://objects/screen_layers/choose_card_ability/choose_card_ability.tscn")

signal player_action(action: Dictionary)

var available_abilities: Dictionary = {}
var available_summons: Array[int] = []

func uncover():
	super.uncover()
	
	battle_scene.set_preview_card(null)
	
	ClickTargetManager.set_criteria(ClickTargetGroup.LAYER_HAND | ClickTargetGroup.LAYER_FIELD, func (cl: ClickTarget):
		if !cl.location:
			return false
		return true
	)
	
	battle_scene.set_screen_label("Your Turn")

func _choose_summon_location(card_instance: CardInstance):
	var screen := battle_scene.push_screen(choose_field_location_scene)
	
	var location = await screen.location_picked
	
	if location:
		emit_signal("player_action", { type = "play_unit", card = card_instance, where = location })
		battle_scene.pop_screen()

func _choose_card_action(card_plane: CardPlane):
	var card := card_plane.card
	assert(card_plane.card)
	battle_scene.push_screen(choose_unit_action_scene, func (screen):
		screen.card_plane = card_plane
		screen.action_chosen.connect(self._choose_card_action_decided)
	)

func _choose_card_action_decided(action: Dictionary):
	if action == null:
		return
	print("Action chosen: ", action)
	match action.type:
		"ability":
			var card_instance := battle_state.get_card_at(action.where)
			if card_instance.uid in available_abilities:
				battle_scene.push_screen(choose_card_ability_scene, func (screen):
					screen.card_instance = card_instance
					screen.allowed_ability_types.append_array([
						CardAbility.CardAbilityType.ACTION,
						CardAbility.CardAbilityType.ATTACK,
					])
					screen.allowed_ability_indices = available_abilities[card_instance.uid]
					screen.ability_chosen.connect(self._choose_card_action_ability_chosen)
				)

func _choose_card_action_ability_chosen(card_instance: CardInstance, index: int):
	if index == -1:
		return
	
	assert(index >= 0)
	assert(index < card_instance.card.abilities.size())
	print("Activating ability%s on %s" % [index, card_instance])
	
	emit_signal("player_action", { type = "activate_ability", location = card_instance.location, ability_index = index })
	battle_scene.pop_screen()

func _on_click_target_agent_confirmed(click_target):
	var card_plane: CardPlane = click_target.get_parent()
	match card_plane.location.tuple():
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Hand, var idx]:
			var card_instance := battle_state.player.hand.get_card(idx)
			match card_instance.card.kind:
				Card.Kind.UNIT:
					if card_instance.uid in available_summons:
						_choose_summon_location(card_instance)
				Card.Kind.GRACE:
					if card_instance.uid in available_abilities:
						_play_hand_card(card_plane.location)
		[ZoneLocation.Side.Player, ZoneLocation.Zone.FrontRow, _],\
		[ZoneLocation.Side.Player, ZoneLocation.Zone.BackRow, _]:
			if card_plane.card:
				_choose_card_action(card_plane)
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Stella, _]:
			if card_plane.card:
				_choose_card_action(card_plane)

func _play_hand_card(location: ZoneLocation):
	
	player_action.emit({ type = "activate_ability", location = location, ability_index = 0 })
	battle_scene.pop_screen()

func _on_click_target_agent_cancelled():
	pass



func _on_click_target_agent_click_target_changed(click_target):
	if click_target:
		var parent = click_target.get_parent()
		if "card" in parent:
			battle_scene.set_preview_card(parent.card)
