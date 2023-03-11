@tool
class_name CardPlane extends Node3D

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

@export_flags("Battle", "Player", "Opponent", "Field", "Hand", "Actions") var cursor_layers: int = 0

@export var is_tapped: bool = false:
	get:
		return is_tapped
	set(value):
		is_tapped = value
		refresh()

@export var tween_target: float = -90.0
@export var tween_duration: float = 0.5

@onready var subviewport := $SubViewport
@onready var card_render := $SubViewport/CardRender
@onready var sprite := $Sprite
@onready var cursor_location := %CursorLocation
@onready var action_root := %ActionRoot

var current_tween_target: float = 0
var current_tween: Tween

func _ready():
	cursor_location.layers = cursor_layers
	refresh()

func refresh():
	if not is_inside_tree():
		return
	
	cursor_location.location = location
	
	if show_card:
		card_render.card = card
		subviewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
		sprite.visible = true
		
		if is_tapped and current_tween_target != tween_target:
			_refresh_tween_to(tween_target)
		elif !is_tapped and current_tween_target == tween_target:
			_refresh_tween_to(0)
	else:
		sprite.visible = false

func _refresh_tween_to(where: float):
	if current_tween:
		current_tween.stop()
	current_tween = create_tween()\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_IN_OUT)
	current_tween_target = tween_target
	current_tween.tween_property(sprite, "rotation_degrees", Vector3(0,0,where), tween_duration)
