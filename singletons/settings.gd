@tool
extends Node

signal sprite_filter_trilinear_changed
var sprite_filter_trilinear: bool = true:
	get:
		return sprite_filter_trilinear
	set(value):
		sprite_filter_trilinear = value
		emit_signal("sprite_filter_trilinear_changed")

func _ready():
	if Engine.is_editor_hint():
		process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta):
	if Input.is_action_just_pressed("toggle_filter_mode"):
		sprite_filter_trilinear = !sprite_filter_trilinear
