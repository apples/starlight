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
@onready var ability0_cursor := %CardAbilityCursorLocation0
@onready var ability1_cursor := %CardAbilityCursorLocation1

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
	
	ability0_cursor.position = card_render.ability0.global_position
	ability0_cursor.set_deferred("size", card_render.ability0.size)
	
	ability1_cursor.position = card_render.ability1.global_position
	ability1_cursor.set_deferred("size", card_render.ability1.size)
