extends CardTask

var who: ZoneLocation.Side = ZoneLocation.Side.Player
var allowed_locations: Array[ZoneLocation]
var target_count: int

var _selected_targets: Array[ZoneLocation]

func start() -> void:
	# Target selection
	
	if target_count == 0:
		return done(_selected_targets)
	
	if allowed_locations.size() < target_count:
		info("Target selection no longer valid")
		breakpoint
		return fail(_selected_targets)
	
	goto(pick_next_target)

func pick_next_target():
	var m := MessageTypes.ChooseTarget.new()
	m.future = Future.new()
	m.allowed_locations = allowed_locations
	m.source_location = ability_instance.source_location
	battle_state.send_message_to(ability_instance.controller, m)
	wait_for_future(m.future, next_target_chosen)

func next_target_chosen(target: ZoneLocation) -> void:
	if target == null:
		return fail()
	
	var idx: int = -1
	for i in range(allowed_locations.size()):
		var t := allowed_locations[i]
		if t.equals(target):
			idx = i
			break
	
	if idx == -1:
		print("Invalid payload")
		return fail(_selected_targets)
	
	allowed_locations.remove_at(idx)
	_selected_targets.append(target)
	
	if _selected_targets.size() < target_count:
		return goto(pick_next_target)
	
	done(_selected_targets)
