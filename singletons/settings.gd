@tool
extends Node


var material_sprite_canvasmaterial_path := "res://objects/material_sprite/material_sprite_canvasmaterial.tres"

signal sprite_filter_trilinear_changed
var sprite_filter_trilinear: bool = true:
	get:
		return sprite_filter_trilinear
	set(value):
		sprite_filter_trilinear = value
		print("sprite_filter_trilinear: ", sprite_filter_trilinear)
		var mat: ShaderMaterial = load(material_sprite_canvasmaterial_path)
		mat.set_shader_parameter("sprite_filter_trilinear", sprite_filter_trilinear)
		emit_signal("sprite_filter_trilinear_changed")

func _ready():
	if Engine.is_editor_hint():
		process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta):
	if Input.is_action_just_pressed("toggle_filter_mode"):
		sprite_filter_trilinear = !sprite_filter_trilinear
