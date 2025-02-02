@tool
extends CardAbilityEffect

enum Status {
	POWER = 1,
}

enum Duration {
	THIS_ATTACK = 1,
	UNTIL_END_OF_TURN = 2,
	UNTIL_START_OF_NEXT_TURN = 3,
}

@export var status: Status = Status.POWER
@export var status_strength: int = 1
@export var status_duration: Duration = Duration.THIS_ATTACK

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
