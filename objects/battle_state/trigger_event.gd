class_name TriggerEvent extends RefCounted

var is_ongoing: bool = false

func _init(fields: Dictionary):
	for k in fields:
		assert(k != "type")
		assert(k in self)
		self[k] = fields[k]
