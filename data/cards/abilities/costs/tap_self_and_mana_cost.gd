extends CardAbilityCost

@export var tap_self: bool = true
@export var mana_amount: int = 0

func can_be_paid(battle_state: BattleState, card_instance: CardInstance, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	if tap_self:
		var self_unit := battle_state.get_unit(card_instance.location)
		
		# Short circuit if not a unit
		if not self_unit:
			return false
		
		# If it's already tapped, we can't tap it (incredible)
		if self_unit.is_tapped:
			return false
	
	# If there is no mana cost, short circuit
	if mana_amount == 0:
		return true
	
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
			
			if count >= mana_amount:
				return true
	
	return false

func pay_task() -> CardTask:
	return PayTask.new(mana_amount)

class PayTask extends CardTask:
	var _mana_amount: int
	
	func _init(mana_amount: int):
		_mana_amount = mana_amount
	
	func start() -> void:
		var card_instance := ability_instance.card_instance
		
		# Cannot be paid unless controlled by user
		if card_instance.location.side != ability_instance.controller:
			push_error("Ability can only be used by owner")
			return fail()
		
		# Perform self-tap
		
		var self_unit := battle_state.get_unit(ability_instance.card_instance.location)
		assert(not self_unit.is_tapped)
		if self_unit.is_tapped:
			push_error("Invalid payload: Unit already tapped")
			return fail()
		battle_state.set_tapped(ability_instance.card_instance.unit)
		
		
		# If there is no mana cost, short circuit
		if _mana_amount == 0:
			return done()
		
		# Mana cost
		
		var tappable := battle_state.get_tappable_units(ability_instance.controller, [card_instance.uid])
		
		# Request taps
		var m := MessageTypes.RequestManaTaps.new()
		m.action_future = Future.new()
		m.amount = _mana_amount
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
				push_error("Invalid payload: unit_location is null")
				return fail()
			var unit_is_tappable: bool = is_tappable.call(unit_location)
			assert(unit_is_tappable)
			if not unit_is_tappable:
				push_error("Invalid payload: unit_location is not tappable")
				return fail()
			var unit := battle_state.get_unit(unit_location)
			assert(unit)
			if not unit:
				push_error("Invalid payload: no unit at unit_location")
				return fail()
			units.append(unit)
		
		for unit in units:
			battle_state.set_tapped(unit)
		
		done()
