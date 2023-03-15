@tool
class_name CardAbilityEffect
extends Resource

func get_attack_damage() -> String:
	return ""

func task() -> CardTask:
	assert(false, "task() not implemented")
	return null

func create_task() -> CardTask:
	var t := task()
	if t.filename == "":
		t.filename = get_script().resource_path.get_file()
	return t
