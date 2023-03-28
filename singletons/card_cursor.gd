extends Node

var agents: Array[CardCursorAgent] = []

var current_cursor_location: CursorLocation = null:
	get:
		return current_cursor_location
	set(value):
		if current_cursor_location == value:
			return
		if current_cursor_location:
			current_cursor_location.is_current = false
		current_cursor_location = value
		if current_cursor_location:
			current_cursor_location.is_current = true
		cursor_location_changed.emit(current_cursor_location)
		var agent := get_current_agent()
		if agent:
			agent.last_location = current_cursor_location
			agent.cursor_location_changed.emit(current_cursor_location)

var enabled_cursor_locations: Array[CursorLocation] = []

signal cursor_location_changed(cursor_location: CursorLocation)

func add_agent(agent: CardCursorAgent):
	agents.append(agent)
	agent.last_location = current_cursor_location
	agent.tree_exiting.connect(func (): _on_agent_tree_exiting(agent))

func get_current_agent() -> CardCursorAgent:
	if agents.size() > 0:
		return agents.back()
	else:
		return null

func add_location(location: CursorLocation):
	if location.enabled:
		enabled_cursor_locations.append(location)
	location.enabled_changed.connect(_on_location_enabled_changed)
	location.confirmed.connect(_on_location_confirmed)
	location.made_current.connect(_on_location_made_current)
	location.tree_exiting.connect(func (): _on_location_tree_exiting(location))

func _on_agent_tree_exiting(agent: CardCursorAgent):
	var idx := agents.find(agent)
	assert(idx != -1)
	agents.remove_at(idx)
	if idx == agents.size() and idx > 0:
		if agents.back().last_location and agents.back().last_location.enabled:
			current_cursor_location = agents.back().last_location
		else:
			current_cursor_location = null

func _on_location_enabled_changed(location: CursorLocation, enabled: bool):
	if enabled:
		assert(not location in enabled_cursor_locations)
		enabled_cursor_locations.append(location)
	else:
		var idx := enabled_cursor_locations.find(location)
		assert(idx != -1)
		enabled_cursor_locations.remove_at(idx)
		if current_cursor_location == location:
			assert(location.is_current)
			current_cursor_location = null

func _on_location_confirmed(cursor_location: CursorLocation):
	if cursor_location.enabled:
		current_cursor_location = cursor_location
		var agent := get_current_agent()
		if agent:
			agent.confirm(current_cursor_location)

func _on_location_made_current(cursor_location: CursorLocation):
	if cursor_location.enabled:
		current_cursor_location = cursor_location

func _on_location_tree_exiting(location: CursorLocation):
	location.enabled = false

## Disables the current node and attempts to nudge the current location to
## the best other enabled location.
func disable_current_and_nudge():
	current_cursor_location.temporary_disable = true
	if _nudge_to_enabled():
		return
	# TODO: perform directional search
	if enabled_cursor_locations.size() > 0:
		current_cursor_location = enabled_cursor_locations[0]
	else:
		current_cursor_location == null
	current_cursor_location.temporary_disable = false
	current_cursor_location.enabled = false

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


func _nudge_to_enabled() -> bool:
	if current_cursor_location and current_cursor_location.enabled:
		return true
	for d in ["right", "up", "down", "left"]:
		if navigate(d):
			return true
	current_cursor_location = null
	return false

func _unhandled_input(event):
	if not get_current_agent():
		return
	
	var nav_dir: StringName = StringName()
	
	if event.is_action_pressed("up"):
		nav_dir = "up"
	elif event.is_action_pressed("down"):
		nav_dir = "down"
	elif event.is_action_pressed("left"):
		nav_dir = "left"
	elif event.is_action_pressed("right"):
		nav_dir = "right"
	
	if nav_dir:
		get_viewport().set_input_as_handled()
		navigate(nav_dir)
		# TODO: play bonk sfx
	
	
	if event.is_action_pressed("confirm"):
		if current_cursor_location:
			get_viewport().set_input_as_handled()
			current_cursor_location.confirm()
	
	if event.is_action_pressed("cancel"):
		if current_cursor_location:
			get_viewport().set_input_as_handled()
			var agent := get_current_agent()
			if agent:
				agent.cancel()
