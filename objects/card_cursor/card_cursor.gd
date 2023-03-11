class_name CardCursor extends Node

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
		cursor_location_changed.emit(current_cursor_location)

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
		navigate(nav_dir)
		# TODO: play bonk sfx

## Attempts to move the current location to the next location in the specified direction.
## If the cursor is not at any location, an attempt is made to place it at a good starting location.
## Returns true if the location changed.
func navigate(nav_dir: String):
	if !current_cursor_location:
		current_cursor_location = CursorLocation.find_location(get_tree(), ZoneLocation.new(ZoneLocation.Side.Player, ZoneLocation.Zone.Hand, 0), CursorLocation.LAYER_BATTLE)
		if !current_cursor_location:
			current_cursor_location = CursorLocation.find_location(get_tree(), ZoneLocation.new(ZoneLocation.Side.Player, ZoneLocation.Zone.BackRow, 1), CursorLocation.LAYER_BATTLE)
		return current_cursor_location != null
	else:
		var next := current_cursor_location.navigate(nav_dir)
		if next:
			current_cursor_location = next
			return true
	
	return false

## Disables the current cursor location and attempts to find a next location.
func disable_current():
	assert(current_cursor_location)
	current_cursor_location.enabled = false
	for d in ["right", "up", "down", "left"]:
		if navigate(d):
			break
