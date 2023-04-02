extends Node

var agents: Array[ClickTargetAgent] = []

var groups: Array[ClickTargetGroup] = []

var current_click_target: ClickTarget = null:
	get:
		return current_click_target
	set(value):
		if current_click_target == value:
			return
		if current_click_target:
			current_click_target.is_current = false
		current_click_target = value
		if current_click_target:
			current_click_target.is_current = true
		click_target_changed.emit(current_click_target)
		var agent := get_current_agent()
		if agent:
			agent.last_click_target = current_click_target
			agent.click_target_changed.emit(current_click_target)

signal click_target_changed(click_target: ClickTarget)

var _criteria

func add_agent(agent: ClickTargetAgent):
	agents.append(agent)
	agent.last_click_target = current_click_target

func remove_agent(agent: ClickTargetAgent):
	assert(agent in agents)
	agents.remove_at(agents.find(agent))
	if agents.size() > 0:
		if agents.back().last_click_target and agents.back().last_click_target.enabled:
			current_click_target = agents.back().last_click_target
		else:
			reset_current_target()

func get_current_agent() -> ClickTargetAgent:
	if agents.size() > 0:
		return agents.back()
	else:
		return null


func add_group(group: ClickTargetGroup):
	groups.append(group)
	group.click_target_added.connect(_on_group_click_target_added)
	group.click_target_removed.connect(_on_group_click_target_removed)
	
	for t in group.targets:
		_on_group_click_target_added(t)

func remove_group(group: ClickTargetGroup):
	assert(group in groups)
	groups.remove_at(groups.find(group))


func reset_current_target():
	for i in range(groups.size() - 1, -1, -1):
		var g := groups[i]
		for target in g.targets:
			if target.enabled:
				current_click_target = target
				return
	current_click_target = null

func dissolve_current_target():
	for t in current_click_target.group.targets:
			if t.enabled:
				current_click_target = t
				return
	reset_current_target()


func set_criteria(group_layer_mask: int, target_filter: Callable) -> Array[ClickTarget]:
	_criteria = [group_layer_mask, target_filter]
	
	var results: Array[ClickTarget] = []
	
	for g in groups:
		for t in g.targets:
			t.enabled = g.matches(group_layer_mask) and target_filter.call(t)
			if t.enabled:
				results.append(t)
	
	return results

## Attempts to move the current click_target to the next click_target in the specified direction.
## If the cursor is not at any click_target, an attempt is made to place it at a good starting click_target.
## Returns true if the click_target changed.
func navigate(nav_dir: String) -> bool:
	if !current_click_target:
		reset_current_target()
		return current_click_target != null
	else:
		var group := current_click_target.group
		assert(group)
		
		# Rows up/down
		
		if nav_dir in ["nav_up", "nav_down"]:
			var index := groups.find(group)
			var d := 1 if nav_dir == "nav_down" else -1
			var e := groups.size() if nav_dir == "nav_down" else -1
			
			for i in range(index + d, e, d):
				for t in groups[i].targets:
					if t.enabled:
						current_click_target = t
						return true
		
		# Targets left/right
		
		if nav_dir in ["nav_left", "nav_right"]:
			var index := group.targets.find(current_click_target)
			assert(index != -1)
			
			var d := 1 if nav_dir == "nav_right" else -1
			var e := group.targets.size() if nav_dir == "nav_right" else -1
			
			for i in range(index + d, e, d):
				if group.targets[i].enabled:
					current_click_target = group.targets[i]
					return true
		
		# Rows left/right
		
		if nav_dir in group and group[nav_dir]:
			for t in group[nav_dir].targets:
				if t.enabled:
					current_click_target = t
					return true
			
			# Start to panic
			
			var index := groups.find(group[nav_dir])
			
			for i in range(index + 1, groups.size()):
				for t in groups[i].targets:
					if t.enabled:
						current_click_target = t
						return true
			
			for i in range(index - 1, -1, -1):
				for t in groups[i].targets:
					if t.enabled:
						current_click_target = t
						return true
	
	return false


func _unhandled_input(event):
	if not get_current_agent():
		return
	
	var nav_dir: String = ""
	
	if event.is_action_pressed("up"):
		nav_dir = "nav_up"
	elif event.is_action_pressed("down"):
		nav_dir = "nav_down"
	elif event.is_action_pressed("left"):
		nav_dir = "nav_left"
	elif event.is_action_pressed("right"):
		nav_dir = "nav_right"
	
	if nav_dir != "":
		get_viewport().set_input_as_handled()
		navigate(nav_dir)
		# TODO: play bonk sfx
	
	
	if event.is_action_pressed("confirm"):
		if current_click_target:
			get_viewport().set_input_as_handled()
			current_click_target.confirm()
	
	if event.is_action_pressed("cancel"):
		if current_click_target:
			get_viewport().set_input_as_handled()
			var agent := get_current_agent()
			if agent:
				agent.cancel()

func _on_group_click_target_added(click_target: ClickTarget):
	if click_target.enabled:
		if _criteria:
			if not click_target.group.matches(_criteria[0]) or not _criteria[1].call(click_target):
				click_target.enabled = false
	
	click_target.enabled_changed.connect(_on_click_target_enabled_changed)
	click_target.confirmed.connect(_on_click_target_confirmed)
	click_target.made_current.connect(_on_click_target_made_current)

func _on_group_click_target_removed(click_target: ClickTarget):
	if click_target == current_click_target:
		dissolve_current_target()


func _on_click_target_enabled_changed(click_target: ClickTarget, enabled: bool):
	if not enabled:
		if current_click_target == click_target:
			assert(click_target.is_current)
			current_click_target = null

func _on_click_target_confirmed(click_target: ClickTarget):
	if click_target.enabled:
		current_click_target = click_target
		var agent := get_current_agent()
		if agent:
			agent.confirm(current_click_target)

func _on_click_target_made_current(click_target: ClickTarget):
	if click_target.enabled:
		current_click_target = click_target
