@tool
extends CardAbilityCost

@export var tap_self: bool = true
@export var mana_amount: int = 0
@export var target_count: int = 0
@export_flags( \
	"Opponent Back:1",
	"Opponent Front:2",
	"Own Front:4",
	"Own Back:8"
	) var target_zones: int = TargetZone.OPPONENT_FRONT
@export var target_zones_var: String

enum TargetZone {
	OPPONENT_BACK = 1,
	OPPONENT_FRONT = 2,
	OWN_FRONT = 4,
	OWN_BACK = 8,
}

func get_mana_cost() -> String:
	return str(mana_amount) if mana_amount != 0 else ""

func can_be_paid(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	# Tap self
	
	if tap_self:
		var self_unit := battle_state.get_unit(card_instance.location)
		
		# Short circuit if not a unit
		if not self_unit:
			return false
		
		# If it's already tapped, we can't tap it (incredible)
		if self_unit.is_tapped:
			return false
	
	# Mana cost
	
	if mana_amount > 0:
		var side_state := battle_state.get_side_state(user_side)
		var all_units := side_state.get_all_units()
		
		# Short circuit if there aren't enough units
		if all_units.size() < mana_amount:
			return false
		
		# Mana is paid by tapping units - check tappable units
		var count: int = 0
		for unit in all_units:
			if unit.card_instance.is_same(card_instance):
				# A card cannot be tapped for mana for its own abilities
				continue
			
			if not unit.is_tapped:
				count += 1
		
		if count < mana_amount:
			return false
	
	# Targets
	
	if target_count and target_zones:
		var possible_locations := Task._get_possible_target_locations(target_zones, user_side)
		
		possible_locations = possible_locations.filter(func (l: ZoneLocation):
			return battle_state.can_be_targeted(l, card_instance, ability_index))
		
		if possible_locations.size() < target_count:
			return false
	
	return true

class Task extends CardTask:
	var tap_self: bool
	var mana_amount: int
	var target_count: int
	var target_zones: int
	
	var _choose_multi_targets = preload("res://objects/tasks/choose_multi_targets.gd")
	
	func start() -> void:
		var card_instance := ability_instance.card_instance
		
		# Cannot be paid unless controlled by user
		if card_instance.location.side != ability_instance.controller:
			push_error("Ability can only be used by owner")
			return fail()
		
		# Perform self-tap
		
		if tap_self:
			var self_unit := battle_state.get_unit(ability_instance.card_instance.location)
			assert(not self_unit.is_tapped)
			if self_unit.is_tapped:
				push_error("Invalid payload: Unit already tapped")
				return fail()
			battle_state.set_tapped(ability_instance.card_instance.unit)
		
		
		# If there is no mana cost, skip to target selection
		if mana_amount == 0:
			return target_selection()
		
		# Mana cost
		
		var tappable := battle_state.get_tappable_units(ability_instance.controller, [card_instance.uid])
		
		# Request taps
		var m := MessageTypes.RequestManaTaps.new()
		m.action_future = Future.new()
		m.amount = mana_amount
		m.available_locations = tappable
		battle_state.send_message_to(ability_instance.controller, m)
		
		wait_for_future(m.action_future, taps_chosen)
	
	func taps_chosen(chosen_locations: Array[ZoneLocation]) -> void:
		
		# Perform mana taps
		
		var units: Array[UnitState] = []
		
		var card_instance := ability_instance.card_instance
		var tappable := battle_state.get_tappable_units(ability_instance.controller, [card_instance.uid])
		
		var is_tappable := func (location: ZoneLocation) -> bool:
			for loc in tappable:
				if loc.equals(location):
					return true
			return false
		
		for unit_location in chosen_locations:
			assert(unit_location)
			if not unit_location:
				print("Invalid payload: unit_location is null")
				return fail()
			var unit_is_tappable: bool = is_tappable.call(unit_location)
			assert(unit_is_tappable)
			if not unit_is_tappable:
				print("Invalid payload: unit_location is not tappable")
				return fail()
			var unit := battle_state.get_unit(unit_location)
			assert(unit)
			if not unit:
				print("Invalid payload: no unit at unit_location")
				return fail()
			units.append(unit)
		
		for unit in units:
			battle_state.set_tapped(unit, true, true)
		
		return goto(target_selection)
	
	func target_selection() -> void:
		var task = _choose_multi_targets.new()
		task.who = ability_instance.controller
		task.allowed_locations = _get_possible_target_locations(target_zones, ability_instance.controller)
		
		task.allowed_locations = task.allowed_locations.filter(func (location: ZoneLocation):
			return battle_state.can_be_targeted(
				location,
				ability_instance.card_instance,
				ability_instance.ability_index))
		
		task.target_count = target_count
		task.ability_instance = ability_instance
		
		wait_for(task, targets_chosen)
	
	func targets_chosen(targets: Array[ZoneLocation]):
		ability_instance.targets = targets
		
		done()
	
	static func _get_possible_target_locations(target_zones: int, user_side: ZoneLocation.Side) -> Array[ZoneLocation]:
		var possible_locations: Array[ZoneLocation] = []
		
		if target_zones & TargetZone.OPPONENT_BACK:
			for i in range(4):
				possible_locations.append(ZoneLocation.new(
					ZoneLocation.flip(user_side), ZoneLocation.Zone.BackRow, i))
		if target_zones & TargetZone.OPPONENT_FRONT:
			for i in range(2):
				possible_locations.append(ZoneLocation.new(
					ZoneLocation.flip(user_side), ZoneLocation.Zone.FrontRow, i))
		if target_zones & TargetZone.OWN_FRONT:
			for i in range(2):
				possible_locations.append(ZoneLocation.new(
					user_side, ZoneLocation.Zone.FrontRow, i))
		if target_zones & TargetZone.OWN_BACK:
			for i in range(4):
				possible_locations.append(ZoneLocation.new(
					user_side, ZoneLocation.Zone.BackRow, i))
		
		return possible_locations
