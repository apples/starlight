extends CardAbilityCost

func can_be_paid(battle_state: BattleState, card_instance: CardInstance, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	var unit := battle_state.get_unit(card_instance.location)
	
	# Short circuit if not a unit
	if not unit:
		return false
	
	# If it's not tapped, we can tap it (incredible)
	if not unit.is_tapped:
		return true
	
	return false

func pay_task() -> CardTask:
	return PayTask.new()

class PayTask extends CardTask:
	func start() -> void:
		var unit := battle_state.get_unit(ability_instance.card_instance.location)
		assert(not unit.is_tapped)
		if unit.is_tapped:
			push_error("Unit already tapped")
			return fail()
		battle_state.set_tapped(ability_instance.card_instance)
		done()
