class_name CardAbilityPassive
extends Resource

func task() -> CardTask:
	var task: CardTask = get_script().Task.new()
	for prop in get_script().get_script_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			task[prop.name] = self[prop.name]
	if task.filename == "":
		task.filename = get_script().resource_path.get_file()
	return task

class CardAbilityPassiveTask extends CardTask:
	var passive_effect: PassiveEffect
	var trigger_event: TriggerEvent
	
	func start():
		var handler := "handle_%s" % trigger_event.get_type()
		if handler in self:
			self.call(handler, trigger_event)
		if not _did_update_state:
			done()
