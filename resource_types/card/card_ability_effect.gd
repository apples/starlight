@tool
class_name CardAbilityEffect
extends Resource

func get_attack_damage() -> String:
	return ""

func create_task(ability_instance: AbilityInstance) -> CardTask:
	var task = get_script().Task.new()
	task.ability_instance = ability_instance
	
	task.assign_props(self)
	
	return task

func get_output_variables() -> Array[String]:
	return []
