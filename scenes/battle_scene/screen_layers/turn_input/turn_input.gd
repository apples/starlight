extends BattleScreenLayer

@onready var cursor := $CardCursor

@export var choose_field_location_scene: PackedScene = preload("res://scenes/battle_scene/screen_layers/choose_field_location/choose_field_location.tscn")
@export var choose_unit_action_scene: PackedScene = preload("res://scenes/battle_scene/screen_layers/choose_unit_action/choose_unit_action.tscn")
@export var choose_card_ability_scene: PackedScene = preload("res://scenes/battle_scene/screen_layers/choose_card_ability/choose_card_ability.tscn")

signal player_action(action: Dictionary)

func _process(delta: float):
	_process_input(delta)

func uncover():
	super.uncover()
	
	CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_HAND | CursorLocation.LAYER_FIELD, func (cl: CursorLocation):
		if !cl.location:
			return false
		return true
	)
	cursor.enabled = true
	
	if cursor.current_cursor_location:
		battle_scene.set_preview_card(battle_state.get_card_at(cursor.current_cursor_location.location))


func cover():
	super.cover()
	cursor.enabled = false
	battle_scene.set_preview_card(null)

func _process_input(delta: float):
	if Input.is_action_just_pressed("confirm"):
		if cursor.current_cursor_location:
			var card_plane: CardPlane = cursor.current_cursor_location.get_parent()
			match card_plane.location.tuple():
				[BattleState.Side.Player, BattleState.Zone.Hand, var idx]:
					var card_instance := battle_state.player.hand[idx]
					match card_instance.card.kind:
						Card.Kind.UNIT:
							_choose_summon_location(card_instance)
				[BattleState.Side.Player, BattleState.Zone.FrontRow, _],\
				[BattleState.Side.Player, BattleState.Zone.BackRow, _]:
					if card_plane.card:
						_choose_unit_action(card_plane)

func _choose_summon_location(card_instance: BattleState.CardInstance):
	var screen := battle_scene.push_screen(choose_field_location_scene)
	
	var location = await screen.location_picked
	
	if location:
		emit_signal("player_action", { type = "play_unit", card = card_instance, where = location })
		battle_scene.pop_screen()

func _choose_unit_action(card_plane: CardPlane):
	assert(card_plane.card && card_plane.card.kind == Card.Kind.UNIT)
	battle_scene.push_screen(choose_unit_action_scene, func (screen):
		screen.card_plane = card_plane
		screen.action_chosen.connect(self._choose_unit_action_decided)
	)

func _choose_unit_action_decided(action: Dictionary):
	if action == null:
		return
	print("Action chosen: ", action)
	match action.type:
		"ability":
			battle_scene.push_screen(choose_card_ability_scene, func (screen):
				screen.card_instance = battle_state.get_card_at(action.where)
				screen.allowed_ability_types.append_array([
					CardAbility.CardAbilityType.ACTION,
					CardAbility.CardAbilityType.ATTACK,
				])
				screen.ability_chosen.connect(self._choose_unit_action_ability_chosen)
			)

func _choose_unit_action_ability_chosen(card_instance: BattleState.CardInstance, index: int):
	if index == -1:
		return
	
	print("Activating ability %s on %s" % [index, card_instance])
	
	var key := "ability%s" % index
	assert(key in card_instance.card)
	battle_state.perform_ability(card_instance, card_instance.card[key] as CardAbility)

func _on_card_cursor_cursor_location_changed(cursor_location: CursorLocation):
	if cursor_location:
		battle_scene.set_preview_card(battle_state.get_card_at(cursor_location.location))
	else:
		battle_scene.set_preview_card(null)
