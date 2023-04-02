@tool
extends CardAbilityCost

# Returns the mana cost as text to display on the card face.
# An empty string will cause the mana cost box to be hidden.
func get_mana_cost() -> String:
	return ""

# Determines if the cost can be paid
func can_be_paid(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	# Cannot be paid unless controlled by user
	if card_instance.location.side != user_side:
		return false
	
	# Check self tap
	var self_unit := battle_state.unit_get(card_instance.location)
	
	# Short circuit if not a unit
	if not self_unit:
		return false
	
	# If it's already tapped, we can't tap it (incredible)
	if self_unit.is_tapped:
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
		
		# Perform self-tap
		
		var self_unit := battle_state.unit_get(ability_instance.card_instance.location)
		assert(not self_unit.is_tapped)
		if self_unit.is_tapped:
			push_error("Invalid payload: Unit already tapped")
			return fail()
		battle_state.unit_set_tapped(ability_instance.card_instance.unit)
		
		done()
