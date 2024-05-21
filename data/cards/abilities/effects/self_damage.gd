@tool
extends CardAbilityEffect

@export var amount: int = 0
@export var amount_var: String = ""

class Task extends CardTask:
	var amount: int
	
	func start() -> void:
		battle_state.deal_damage(ability_instance.card_instance.location, amount)
		done()
