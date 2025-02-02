@tool
extends CardAbilityCost

# Determines if the cost can be paid
func can_be_paid(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	return true

# The task which actually performs the payment
class Task extends CardTask:
	
	# Start of cost execution
	func start() -> void:
		# Get the card which is the source of this effect
		var card_instance := ability_instance.card_instance
		
		# Cannot be paid unless controlled by user
		if card_instance.location.side != ability_instance.controller:
			push_error("Ability can only be used by owner")
			return fail()
		
		push_error("Not implemented.")
		fail()
