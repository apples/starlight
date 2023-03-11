extends CardAbilityCost

@export var amount: int = 0

func can_be_paid(battle_state: BattleState, card_instance: CardInstance, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	var side_state := battle_state.get_side_state(user_side)
	var all_units := side_state.get_all_units()
	
	# Short circuit
	if all_units.size() < amount:
		return false
	
	# Mana is paid by tapping units - check tappable units
	var count: int = 0
	for unit in all_units:
		if unit.card_instance.is_same(card_instance):
			# A card cannot be tapped for mana for its own abilities
			continue
		
		if not unit.is_tapped:
			count += 1
			
			if count >= amount:
				return true
	
	return false

func pay_task() -> CardTask:
	return PayTask.new(amount)

class PayTask extends CardTask:
	var _amount: int
	
	func _init(amount: int):
		_amount = amount
	
	func start() -> void:
		var card_instance := ability_instance.card_instance
		
		# Cannot be paid unless controlled by user
		if card_instance.location.side != ability_instance.controller:
			push_error("Ability can only be used by owner")
			return fail()
		
		var tappable := battle_state.get_tappable_units(ability_instance.controller, [card_instance.uid])
		
		# Request taps
		var m := MessageTypes.RequestManaTaps.new()
		m.action_future = Future.new()
		m.amount = _amount
		m.available_locations = tappable
		battle_state.send_message_to(ability_instance.controller, m)
		
		wait_for_future(m.action_future, taps_chosen)
	
	func taps_chosen(chosen_locations: Array[ZoneLocation]) -> void:
		var units: Array[UnitState] = []
		
		var card_instance := ability_instance.card_instance
		var tappable := battle_state.get_tappable_units(ability_instance.controller, [card_instance.uid])
		
		var is_tappable := func (location: ZoneLocation) -> bool:
			for loc in tappable:
				if loc.equals(location):
					return true
			return false
		
		for unit in chosen_locations:
			assert(unit)
			if not unit:
				push_error("Invalid payload")
				return fail()
			var unit_is_tappable: bool = is_tappable.call(unit.card_instance.location)
			assert(unit_is_tappable)
			if not unit_is_tappable:
				push_error("Invalid payload")
				return fail()
			units.append(unit)
		
		for unit in units:
			battle_state.set_tapped(unit)
		
		done()
