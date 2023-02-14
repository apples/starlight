extends Node3D

@export var enabled: bool = false:
	get:
		return enabled
	set(value):
		enabled = value
		visible = enabled

var current_cursor_location: CursorLocation = null

func _ready():
	pass

func _process(delta: float):
	if !enabled:
		return
	
	var nav_dir: StringName = StringName()
	
	if Input.is_action_just_pressed("up"):
		nav_dir = "up"
	elif Input.is_action_just_pressed("down"):
		nav_dir = "down"
	elif Input.is_action_just_pressed("left"):
		nav_dir = "left"
	elif Input.is_action_just_pressed("right"):
		nav_dir = "right"
	
	if nav_dir != null and current_cursor_location != null:
		var next := current_cursor_location.navigate(nav_dir)
		if next:
			current_cursor_location = next
		else:
			# TODO: play bonk sfx
			pass
	
	if current_cursor_location:
		visible = true
		global_transform = current_cursor_location.global_transform
	else:
		visible = false
	
