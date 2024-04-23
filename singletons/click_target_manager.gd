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

func _ready():
	_apply_current_agent_criteria()

func add_agent(agent: ClickTargetAgent):
	agents.append(agent)
	agent.last_click_target = current_click_target
	agent.criteria_changed.connect(_on_agent_criteria_changed.bind(agent))
	_apply_current_agent_criteria()

func remove_agent(agent: ClickTargetAgent):
	assert(agent in agents)
	agents.remove_at(agents.find(agent))
	_apply_current_agent_criteria()
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

func apply_criteria(group_layer_mask: int, target_filter: Callable) -> void:
	for g in groups:
		for t in g.targets:
			t.enabled = g.matches(group_layer_mask) and (target_filter.call(t) if target_filter else true)

func get_enabled_click_targets() -> Array[ClickTarget]:
	var results: Array[ClickTarget] = []
	
	for g in groups:
		for t in g.targets:
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
	if get_current_agent():
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
		var agent := get_current_agent()
		if agent:
			get_viewport().set_input_as_handled()
			agent.cancel()

func _on_group_click_target_added(click_target: ClickTarget):
	if click_target.enabled:
		var agent := get_current_agent()
		if agent and agent.criteria:
			if not click_target.group.matches(agent.criteria.group_layer_mask):
				click_target.enabled = false
			elif agent.criteria.target_filter and not agent.criteria.target_filter.call(click_target):
				click_target.enabled = false
		else:
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

func _on_agent_criteria_changed(agent: ClickTargetAgent) -> void:
	if agent == get_current_agent():
		_apply_current_agent_criteria()

func _apply_current_agent_criteria() -> void:
	var agent := get_current_agent()
	if agent and agent.criteria:
		apply_criteria(agent.criteria.group_layer_mask, agent.criteria.target_filter)
	else:
		apply_criteria(ClickTargetGroup.LAYER_NONE, Callable())
