@tool
extends CardAbilityEffect

@export var amount: int = 0

# Returns the damage as text to display on the card face
# Only used for Attack get_attack_damage() -> String:

# The task which will perform the effect
class Task extends CardTask:
	var amount: int
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("amount = %s" % amount)
		
		# TODO
		done()
