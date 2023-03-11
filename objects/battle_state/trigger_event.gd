class_name TriggerEvent extends RefCounted

var is_ongoing: bool = false

func get_type() -> String:
	push_error("get_type() not implemented")
	return "unknown"

func _init(fields: Dictionary):
	for k in fields:
		assert(k != "type")
		assert(k in self)
		self[k] = fields[k]
