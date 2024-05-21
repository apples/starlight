@tool
extends CardAbilityEffect

@export var amount: int = 0
@export var amount_var: String

# Called when the engine needs to execute the task
func task() -> CardTask:
	return Task.new()

# The task which will perform the effect
class Task extends CardTask:
	var amount: int
	
	# Start of effect execution
	func start() -> void:
		battle_state.rulecard_charge(ability_instance.controller, amount)
		
		done()
