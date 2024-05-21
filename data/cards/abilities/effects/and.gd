@tool
extends CardAbilityEffect

@export var first_effect: CardAbilityEffect
@export var second_effect: CardAbilityEffect

func get_attack_damage() -> String:
	match [first_effect.get_attack_damage() if first_effect else "", second_effect.get_attack_damage() if second_effect else ""]:
		["", ""]: return ""
		[var a, ""]: return a
		["", var b]: return b
		[var a, var b]: return a + " + " + b
	assert(false, "unreachable")
	return ""

class Task extends CardTask:
	var first_effect: CardAbilityEffect
	var second_effect: CardAbilityEffect
	
	func start() -> void:
		if first_effect:
			wait_for(first_effect.create_task(ability_instance), perform_second)
		else:
			push_error("first_effect is required")
			perform_second()
	
	func perform_second() -> void:
		if second_effect:
			become(second_effect.create_task(ability_instance))
		else:
			push_error("second_effect is required")
			fail()
