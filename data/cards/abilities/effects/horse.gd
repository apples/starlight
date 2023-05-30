@tool
extends CardAbilityEffect

@export var amount: int = 0

# Returns the damage as text to display on the card face
# Only used for Attacks
func get_attack_damage() -> String:
	return str(amount)

# The task which will perform the effect
class Task extends CardTask:
	var amount: int
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("amount = %s" % amount)
		
		# Get the opponent's side
		var opponent_side := ZoneLocation.flip(ability_instance.controller)
		
		# Create a message to send to the player agent
		var choose := ChooseTargetTask.new()
		choose.allowed_locations = [
			ZoneLocation.new(opponent_side, ZoneLocation.Zone.FrontRow, 0),
			ZoneLocation.new(opponent_side, ZoneLocation.Zone.FrontRow, 1),
		]
		
		# Wait for the player to respond
		wait_for(choose, chosen)
	
	# Called when the player responds to the message
	func chosen(where: ZoneLocation) -> void:
		# Sanity check the player input (might come from over the network)
		assert(where)
		if not where:
			info("Invalid move")
			return done()
		
		# Calculate attack damage including modifiers
		var damage_amount := amount + ability_instance.attack_info.bonus_damage
		
		# Debug info
		info("target location: %s" % where)
		info("total damage: %s" % damage_amount)
		
		# Finalize the damage
		battle_state.deal_damage(where, damage_amount)
		done()
