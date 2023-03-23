@tool
extends CardAbilityEffect

@export var kind: BattleState.TokenType
@export var amount: int = 1
@export var amount_var: String = ""

# The task which will perform the effect
class Task extends CardTask:
	var kind: BattleState.TokenType
	var amount: int
	
	# Start of effect execution
	func start() -> void:
		
		battle_state.gain_tokens(ability_instance.controller, kind, amount)
		
		done()
