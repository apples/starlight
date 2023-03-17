class_name TriggerEvent extends RefCounted

var is_respondable: bool = true

func get_type() -> String:
	push_error("get_type() not implemented")
	return "unknown"

func _init(fields: Dictionary):
	for k in fields:
		assert(k != "type")
		assert(k in self)
		self[k] = fields[k]

func _to_string():
	var s := "TriggerEvent(%s):" % get_type()
	for k in self.get_script().get_script_property_list():
		if k.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			s += " %s = %s," % [k.name, self[k.name]]
	s += ">"
	return s
