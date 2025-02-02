@tool
extends CardAbilityEffect

@export var amount: int = 0

# The task which will perform the effect
class Task extends CardTask:
	var amount: int
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("amount = %s" % amount)
		
		# TODO
		done()
