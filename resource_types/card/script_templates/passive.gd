@tool
extends CardAbilityPassive

@export var value: int

class Task extends CardAbilityPassiveTask:
	var value: int
	
	func handle_unit_ascended(e: TriggerEvents.UnitAscended):
		pass

