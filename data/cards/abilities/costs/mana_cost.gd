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
	push_error("CardAbilityCost: pay_task() not implemented")
	return null
