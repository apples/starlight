extends BattleScreenLayer


signal player_action(action: Dictionary)

var available_abilities: Dictionary = {}
var available_summons: Array[int] = []

var choose_unit_action_scene: PackedScene = preload("res://objects/screen_layers/choose_unit_action/choose_unit_action.tscn")
var choose_card_ability_scene: PackedScene = preload("res://objects/screen_layers/choose_card_ability/choose_card_ability.tscn")
var overlay_dialog_scene: PackedScene = preload("res://objects/screen_layers/overlay_dialog/overlay_dialog.tscn")

@onready var click_target_agent: ClickTargetAgent = $ClickTargetAgent

func uncover():
	super.uncover()
	
	battle_scene.set_preview_card(null)
	
	click_target_agent.set_criteria({
		group_layer_mask = ClickTargetGroup.LAYER_HAND | ClickTargetGroup.LAYER_FIELD,
		target_filter = func (cl: ClickTarget):
			return cl.location != null
	})
	
	battle_scene.set_screen_label("Your Turn")

func _play_unit(card_instance: CardInstance):
	battle_scene.pop_screen()
	emit_signal("player_action", { type = "play_unit", uid = card_instance.uid })

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
	
	emit_signal("player_action", { type = "activate_ability", uid = card_instance.uid, ability_index = index })
	battle_scene.pop_screen()

func _on_click_target_agent_confirmed(click_target):
	var card_plane: CardPlane = click_target.get_parent()
	match card_plane.location.tuple():
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Hand, var idx]:
			var card_instance := battle_state.player.hand.get_card(idx)
			match card_instance.card.kind:
				Card.Kind.UNIT:
					if card_instance.uid in available_summons:
						_play_unit(card_instance)
				Card.Kind.GRACE:
					if card_instance.uid in available_abilities:
						_play_hand_card(card_instance)
		[ZoneLocation.Side.Player, ZoneLocation.Zone.FrontRow, _],\
		[ZoneLocation.Side.Player, ZoneLocation.Zone.BackRow, _]:
			if card_plane.card:
				_choose_card_action(card_plane)
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Stella, _]:
			if card_plane.card:
				_choose_card_action(card_plane)

func _play_hand_card(card_instance: CardInstance):
	battle_scene.pop_screen()
	player_action.emit({ type = "activate_ability", uid = card_instance.uid, ability_index = 0 })

func _on_click_target_agent_cancelled():
	battle_scene.push_screen(overlay_dialog_scene, func (screen):
		screen.text = "End Turn?"
		screen.options = ["Yes", "No"] as Array[String]
		var response = await screen.action_chosen
		if response == "Yes":
			battle_scene.pop_screen()
			player_action.emit({ type = "end_turn" })
	)



func _on_click_target_agent_click_target_changed(click_target):
	if click_target:
		var parent = click_target.get_parent()
		if "card" in parent:
			battle_scene.set_preview_card(parent.card)
