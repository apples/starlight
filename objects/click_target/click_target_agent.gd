class_name ClickTargetAgent extends Node

static var current: ClickTargetAgent

var last_click_target: ClickTarget

signal click_target_changed(click_target: ClickTarget)
signal confirmed(click_target: ClickTarget)
signal cancelled()
signal criteria_changed()

var criteria: Variant: set = set_criteria # null | { group_layer_mask: int, target_filter: Callable }

func _enter_tree() -> void:
	ClickTargetManager.add_agent(self)

func _exit_tree() -> void:
	ClickTargetManager.remove_agent(self)

func confirm(click_target: ClickTarget):
	confirmed.emit(click_target)

func cancel():
	cancelled.emit()

func set_criteria(p_criteria: Variant) -> void:
	if p_criteria != null:
		assert(typeof(p_criteria) == TYPE_DICTIONARY)
		assert(typeof(p_criteria["group_layer_mask"]) == TYPE_INT)
		assert("group_layer_mask" in p_criteria)
		if "target_filter" in p_criteria:
			assert(typeof(p_criteria["target_filter"]) == TYPE_CALLABLE)
	
	criteria = {
		group_layer_mask = p_criteria.group_layer_mask,
		target_filter = p_criteria.target_filter if "target_filter" in p_criteria else Callable(),
	}
	
	criteria_changed.emit()

func get_enabled_click_targets() -> Array[ClickTarget]:
	assert(ClickTargetManager.get_current_agent() == self)
	return ClickTargetManager.get_enabled_click_targets()
