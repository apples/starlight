@tool
extends CardAbilityEffect

@export var kind: BattleState.TokenType
@export var amount: int = 0

# Called when the engine needs to execute the task
func task() -> CardTask:
	return Task.new(kind, amount)

# The task which will perform the effect
class Task extends CardTask:
	var kind: BattleState.TokenType
	var amount: int
	
	# Initialize with parameters from above
	func _init(p_kind: BattleState.TokenType, p_amount: int):
		kind = p_kind
		amount = p_amount
	
	# Start of effect execution
	func start() -> void:
		battle_state.gain_tokens(ability_instance.controller, kind, amount)
		
		done()
