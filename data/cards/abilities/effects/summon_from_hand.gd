@tool
extends CardAbilityEffect

# Returns the damage as text to display on the card face
# Only used for Attacks
func get_attack_damage() -> String:
	return ""

# The task which will perform the effect
class Task extends CardTask:
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("not implemented")
		
		fail()
