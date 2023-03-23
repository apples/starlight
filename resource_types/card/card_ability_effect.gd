@tool
class_name CardAbilityEffect
extends Resource

func get_attack_damage() -> String:
	return ""

func create_task(ability_instance: AbilityInstance) -> CardTask:
	var task = get_script().Task.new()
	task.ability_instance = ability_instance
	
	for prop in get_script().get_script_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			# Skip over variable props
			if prop.name.ends_with("_var"):
				continue
			
			# Check for an apply variable prop instead of value
			var varkey: String = prop.name + "_var"
			if varkey in self:
				var varname: String = self[varkey]
				if varname != "":
					assert(ability_instance != null)
					assert(varname in ability_instance.variables)
					task[prop.name] = ability_instance.variables[varname]
					continue
			
			task[prop.name] = self[prop.name]
	
	if task.filename == "":
		task.filename = get_script().resource_path.get_file()
	
	return task
