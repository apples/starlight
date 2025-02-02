@tool
extends CardAbilityEffect

@export var amount: int = 0
@export var amount_var: String = ""


class Task extends CardTask:
	var amount: int
	
	func start() -> void:
		for target: ZoneLocation in ability_instance.targets:
			if battle_state.unit_get(target) == null:
				continue
			
			battle_state.deal_damage(target, amount)
			
