extends BattleScreenLayer

@onready var cursor := $CardCursor

@export var choose_field_location_scene: PackedScene = preload("res://scenes/battle_scene/screen_layers/choose_field_location/choose_field_location.tscn")
@export var choose_unit_action_scene: PackedScene = preload("res://scenes/battle_scene/screen_layers/choose_unit_action/choose_unit_action.tscn")

signal player_action(action: Dictionary)

func _process(delta: float):
	_process_input(delta)

func uncover():
	super.uncover()
	
	CursorLocation.filter_enable(get_tree(), CursorLocation.LAYER_BATTLE, func (cl: CursorLocation):
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
				[BattleState.Side.Player, BattleState.Zone.FrontRow, var idx]:
					_choose_unit_action(battle_state.player.front_row[idx], card_plane.location)
				[BattleState.Side.Player, BattleState.Zone.BackRow, var idx]:
					_choose_unit_action(battle_state.player.back_row[idx], card_plane.location)

func _choose_summon_location(card_instance: BattleState.CardInstance):
	var screen := battle_scene.push_screen(choose_field_location_scene)
	
	var location = await screen.location_picked
	
	if location:
		emit_signal("player_action", { type = "play_unit", card = card_instance, where = location })
		battle_scene.pop_screen()

func _choose_unit_action(card_instance: BattleState.UnitState, location: BattleState.ZoneLocation):
	var screen := battle_scene.push_screen(choose_unit_action_scene)
	#screen.card_instance = 
	screen.location = location



func _on_card_cursor_cursor_location_changed(cursor_location: CursorLocation):
	battle_scene.set_preview_card(battle_state.get_card_at(cursor_location.location))
