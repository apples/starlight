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

@onready var sprite := $Sprite
@onready var viewport := $SubViewport
@onready var card_render: CardRender = %CardRender
@onready var cursor_locations = %CursorLocations

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
	
	for i in range(card_render.ability_container.get_child_count()):
		var ability_panel := card_render.ability_container.get_child(i)
		var cl: CursorLocation
		if i < cursor_locations.get_child_count():
			cl = cursor_locations.get_child(i)
		else:
			cl = card_ability_cursor_location.instantiate()
			cl.layers = CursorLocation.LAYER_BATTLE | CursorLocation.LAYER_CARD_ABILITIES
			cursor_locations.add_child(cl)
		
		cl.custom_tag = "ability%s" % i
		cl.track_control = ability_panel
		cl.scale *= sprite.scale
	
	for i in range(card_render.ability_container.get_child_count(), cursor_locations.get_child_count()):
		cursor_locations.get_child(i).queue_free()
	
	# Fix navigation links
	for i in range(cursor_locations.get_child_count()):
		var cl := cursor_locations.get_child(i)
		
		if i > 0:
			cl.up = cursor_locations.get_child(i - 1)
		else:
			cl.up = null
		
		if i < cursor_locations.get_child_count() - 1:
			cl.down = cursor_locations.get_child(i + 1)
		else:
			cl.down = null
