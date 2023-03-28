@tool
extends Control

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		refresh()

@export var show_card: bool = true:
	get:
		return show_card
	set(value):
		show_card = value
		refresh()

@export var location: ZoneLocation = null:
	get:
		return location
	set(value):
		location = value
		refresh()

@onready var sprite = $Sprite
@onready var viewport = $SubViewport
@onready var card_render: CardRender = %CardRender
@onready var ability_overlays = %AbilityOverlays

var card_ability_cursor_location := preload("res://objects/card_ability_cursor_location/card_ability_cursor_location.tscn")

func _ready():
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	if not show_card:
		sprite.visible = false
		return
	
	sprite.visible = true
	
	card_render.card = card
	viewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	
	if Engine.is_editor_hint():
		return
	
	for i in range(card_render.ability_panels.size()):
		var ability_panel: Control = card_render.ability_panels[i]
		var ability_overlay: Control
		if i < ability_overlays.get_child_count():
			ability_overlay = ability_overlays.get_child(i)
		else:
			ability_overlay = card_ability_cursor_location.instantiate()
			ability_overlays.add_child(ability_overlay)
		
		var cl: CursorLocation = ability_overlay.cursor_location
		cl.custom_tag = "ability%s" % i
		
		ability_overlay.scale = Vector2(0.5, 0.5) * sprite.size / sprite.texture.get_size()
		ability_overlay.size = ability_panel.size / ability_overlay.scale
		ability_overlay.position = ability_panel.global_position
	
	for i in range(card_render.ability_panels.size(), ability_overlays.get_child_count()):
		ability_overlays.get_child(i).queue_free()
	
	# Fix navigation links
	for i in range(ability_overlays.get_child_count()):
		var cl: CursorLocation = ability_overlays.get_child(i).cursor_location
		
		if i > 0:
			cl.up = ability_overlays.get_child(i - 1).cursor_location
		else:
			cl.up = null
		
		if i < ability_overlays.get_child_count() - 1:
			cl.down = ability_overlays.get_child(i + 1).cursor_location
		else:
			cl.down = null


func _on_sub_viewport_size_changed():
	if not Engine.is_editor_hint():
		print("wtf")
