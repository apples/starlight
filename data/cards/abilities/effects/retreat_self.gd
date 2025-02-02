@tool
extends CardAbilityEffect


# The task which will perform the effect
class Task extends CardTask:
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("not implemented")
		
		fail()
