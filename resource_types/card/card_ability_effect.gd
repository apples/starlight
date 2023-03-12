class_name CardAbilityEffect
extends Resource

func task() -> CardTask:
	assert(false, "task() not implemented")
	return null

func create_task() -> CardTask:
	var t := task()
	if t.filename == "":
		t.filename = get_script().resource_path.get_file()
	return t
