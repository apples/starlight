extends Node

@export var enabled: bool = false:
	get:
		return enabled
	set(value):
		enabled = value

var current_cursor_location: CursorLocation = null:
	get:
		return current_cursor_location
	set(value):
		if current_cursor_location:
			current_cursor_location.is_current = false
		current_cursor_location = value
		if current_cursor_location:
			current_cursor_location.is_current = true
		emit_signal("cursor_location_changed", current_cursor_location)

signal cursor_location_changed(cursor_location: CursorLocation)

func _ready():
	pass

func _exit_tree():
	if current_cursor_location:
		current_cursor_location.is_current = false

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
	
	if nav_dir:
		if !current_cursor_location:
			current_cursor_location = CursorLocation.find_location(get_tree(), ZoneLocation.new(ZoneLocation.Side.Player, ZoneLocation.Zone.Hand, 0), CursorLocation.LAYER_BATTLE)
			if !current_cursor_location:
				current_cursor_location = CursorLocation.find_location(get_tree(), ZoneLocation.new(ZoneLocation.Side.Player, ZoneLocation.Zone.BackRow, 1), CursorLocation.LAYER_BATTLE)
		else:
			var next := current_cursor_location.navigate(nav_dir)
			if next:
				current_cursor_location = next
			else:
				# TODO: play bonk sfx
				pass
