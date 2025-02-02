@tool
extends CardAbilityEffect

@export var amount: int = 1


# The task which will perform the effect
class Task extends CardTask:
	var amount: int
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("draw amount = %s" % amount)
		
		assert(amount >= 0)
		for i in range(amount):
			battle_state.draw_card(ability_instance.controller)
		
		done()
