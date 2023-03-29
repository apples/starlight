@tool
extends CardAbilityCost

@export var charge_cost: int = 0


@export var target_discard: int = 0


@export var target_units: int = 0
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


# Determines if the cost can be paid
func can_be_paid(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	var side_state := battle_state.get_side_state(user_side)
	
	# Stella charge
	
	if side_state.stella_charge < charge_cost:
		return false
	
	# Target discards
	
	if target_discard:
		if side_state.discard.size() < target_discard:
			return false
	
	# Target units
	
	if target_units and target_zones:
		var possible_locations := Task._get_possible_target_locations(target_zones, user_side)
		
		possible_locations = possible_locations.filter(func (l: ZoneLocation):
			return battle_state.ability_can_target_location(card_instance, ability_index, l))
		
		if possible_locations.size() < target_units:
			return false
	
	return true

# The task which actually performs the payment
class Task extends CardTask:
	var charge_cost: int
	var target_discard: int
	var target_units: int
	var target_zones: int
	
	var _choose_multi_targets = preload("res://objects/tasks/choose_multi_targets.gd")
	
	# Start of cost execution
	func start() -> void:
		# Get the card which is the source of this effect
		var card_instance := ability_instance.card_instance
		
		# Cannot be paid unless controlled by user
		if card_instance.location.side != ability_instance.controller:
			push_error("Ability can only be used by owner")
			return fail()
		
		if battle_state.get_side_state(ability_instance.controller).stella_charge < charge_cost:
			push_error("Ability cannot be paid")
			return fail()
		
		# Stella charge
		
		battle_state.stella_charge(ability_instance.controller, -charge_cost)
		
		# Target discard
		
		if target_discard:
			pass # TODO
		
		return goto(unit_target_selection)
	
	func unit_target_selection() -> void:
		var task = _choose_multi_targets.new()
		task.who = ability_instance.controller
		task.allowed_locations = _get_possible_target_locations(target_zones, ability_instance.controller)
		
		task.allowed_locations = task.allowed_locations.filter(func (location: ZoneLocation):
			return battle_state.ability_can_target_location(
				ability_instance.card_instance,
				ability_instance.ability_index,
				location))
		
		task.target_count = target_units
		task.ability_instance = ability_instance
		
		wait_for(task, unit_targets_chosen)
	
	func unit_targets_chosen(targets: Array[ZoneLocation]):
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
