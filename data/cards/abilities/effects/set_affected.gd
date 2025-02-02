@tool
extends CardAbilityEffect

enum Who {
	TARGET = 1,
	SELF = 2,
}

@export var who: Who = Who.TARGET

@export var effect: CardAbilityEffect = null


# The task which will perform the effect
class Task extends CardTask:
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("not implemented")
		
		fail()
