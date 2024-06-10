@tool
extends CardAbilityCost

@export var tap_self: bool = true

@export var mana_amount: int = 0

@export var once_per_turn: bool = false

@export var unit_target_count: int = 0

@export_flags( \
	"Opponent Back:1",
	"Opponent Front:2",
	"Own Front:4",
	"Own Back:8"
	) var unit_target_zones: int = TargetZone.OPPONENT_FRONT
@export var unit_target_zones_var: String

@export var discard_target_count: int = 0

@export_flags("Own:1", "Opponent:2") var discard_target_sides: int = 1

@export var rulecard_charge_cost: int = 0

enum TargetZone {
	OPPONENT_BACK = 1,
	OPPONENT_FRONT = 2,
	OWN_FRONT = 4,
	OWN_BACK = 8,
	FRONT = OPPONENT_FRONT | OWN_FRONT,
	BACK = OPPONENT_BACK | OWN_BACK,
	OPPONENT = OPPONENT_BACK | OPPONENT_FRONT,
	OWN = OWN_FRONT | OWN_BACK,
	ANY = OPPONENT | OWN,
}

enum DiscardSide {
	OPPONENT = 1,
	OWN = 2,
}

func get_property_display(prop: StringName) -> bool:
	match prop:
		&"unit_target_zones":
			return unit_target_count != 0
		&"discard_target_sides":
			return discard_target_count != 0
	return true

func get_mana_cost() -> int:
	return mana_amount

func get_requires_tap() -> bool:
	return tap_self

func can_be_paid(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	var side_state := battle_state.get_side_state(user_side)
	
	# Tap self
	
	if tap_self:
		var self_unit := battle_state.unit_get(card_instance.location)
		
		# Short circuit if not a unit
		if not self_unit:
			return false
		
		# If it's already tapped, we can't tap it (incredible)
		if self_unit.is_tapped:
			return false
	
	# Mana cost
	
	if mana_amount > 0:
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
	
	# Once per turn
	
	if once_per_turn:
		var turn_scratch := card_instance.ability_scratch[ability_index].for_turn
		if "once_per_turn_used" in turn_scratch and turn_scratch["once_per_turn_used"]:
			return false
	
	# Unit targets
	
	if unit_target_count > 0:
		if unit_target_zones == 0:
			return false
		
		var possible_locations := Task._get_possible_unit_target_locations(unit_target_zones, user_side)
		
		possible_locations = possible_locations.filter(func (l: ZoneLocation):
			return battle_state.ability_can_target_location(card_instance, ability_index, l))
		
		if possible_locations.size() < unit_target_count:
			return false
	
	# Discard targets
	
	if discard_target_count > 0:
		var total := 0
		
		if discard_target_sides & DiscardSide.OPPONENT:
			total += battle_state.get_side_state(ZoneLocation.flip(user_side)).discard.size()
		
		if discard_target_sides & DiscardSide.OWN:
			total += side_state.discard.size()
		
		if total < discard_target_count:
			return false
	
	# Rulecard charge
	
	if side_state.rulecard_charge < rulecard_charge_cost:
		return false
	
	return true

class Task extends CardTask:
	var tap_self: bool
	var mana_amount: int
	var once_per_turn: bool
	var unit_target_count: int
	var unit_target_zones: int
	var discard_target_count: int
	var discard_target_sides: int
	var rulecard_charge_cost: int

	var _choose_multi_targets = preload("res://objects/tasks/choose_multi_targets.gd")
	
	var _chosen_mana_sources: Array[UnitState] = []
	
	func start() -> void:
		var card_instance := ability_instance.card_instance
		
		# Cannot be paid unless controlled by user
		if card_instance.location.side != ability_instance.controller:
			push_error("Ability can only be used by owner")
			return fail()
		
		# Mana cost
		
		# If there is no mana cost, skip to target selection
		if mana_amount == 0:
			return unit_target_selection()
		
		var tappable := battle_state.get_tappable_units(ability_instance.controller, [card_instance.uid])
		
		# Request taps
		var m := MessageTypes.RequestManaTaps.new({
			action_future = Future.new(),
			amount = mana_amount,
			available_locations = tappable,
		})
		battle_state.send_message_to(ability_instance.controller, m)
		
		wait_for_future(m.action_future, mana_taps_chosen)
	
	func mana_taps_chosen(chosen_locations: Array[ZoneLocation]) -> void:
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
			var unit := battle_state.unit_get(unit_location)
			assert(unit)
			if not unit:
				print("Invalid payload: no unit at unit_location")
				return fail()
			_chosen_mana_sources.append(unit)
		
		return goto(unit_target_selection)
	
	func unit_target_selection() -> void:
		var task = _choose_multi_targets.new()
		task.who = ability_instance.controller
		task.allowed_locations = _get_possible_unit_target_locations(unit_target_zones, ability_instance.controller)
		
		task.allowed_locations = task.allowed_locations.filter(func (location: ZoneLocation):
			return battle_state.ability_can_target_location(
				ability_instance.card_instance,
				ability_instance.ability_index,
				location))
		
		task.target_count = unit_target_count
		task.ability_instance = ability_instance
		
		wait_for(task, unit_targets_chosen)
	
	func unit_targets_chosen(targets: Array[ZoneLocation]) -> void:
		ability_instance.targets = targets
		
		finish()
	
	func finish() -> void:
		# Perform self-tap
		
		if tap_self:
			var self_unit := battle_state.unit_get(ability_instance.card_instance.location)
			assert(not self_unit.is_tapped)
			if self_unit.is_tapped:
				push_error("Invalid payload: Unit already tapped")
				return fail()
			battle_state.unit_set_tapped(ability_instance.card_instance.unit)
		
		# Perform mana taps
		
		for unit in _chosen_mana_sources:
			battle_state.unit_set_tapped(unit, true, true)
		
		# Once per turn
		
		if once_per_turn:
			ability_instance.scratch.for_turn["once_per_turn_used"] = true
		
		# Rulecard charge
		
		battle_state.rulecard_charge(ability_instance.controller, -rulecard_charge_cost)
		
		done()
	
	static func _get_possible_unit_target_locations(target_zones: int, user_side: ZoneLocation.Side) -> Array[ZoneLocation]:
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
	
