class_name TriggerEvents extends Node

class AbilityActivated extends TriggerEvent:
	func get_type(): return "ability_activated"
	var ability_instance: AbilityInstance

class AbilityPerformed extends TriggerEvent:
	func get_type(): return "ability_performed"
	var ability_instance: AbilityInstance
