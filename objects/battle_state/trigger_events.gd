class_name TriggerEvents extends Node

class AbilityActivated extends TriggerEvent:
	func get_type(): return "ability_activated"
	var ability_instance: AbilityInstance
