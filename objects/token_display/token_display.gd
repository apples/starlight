extends Node3D

@export_enum("Up:1", "Down:-1") var direction = 1
@export var separation: float = 1.0

var token_display_item := preload("res://objects/token_display/token_display_item.tscn")

func set_amounts(amounts: Dictionary):
	var flat := []
	for key in amounts:
		flat.append([key, amounts[key]])
	flat.sort_custom(func (a, b):
		return a[1] > b[1])
	for i in range(flat.size()):
		var kind = flat[i][0]
		var amount = flat[i][1]
		var item
		while get_child_count() <= i:
			add_child(token_display_item.instantiate())
		item = get_child(i)
		item.kind = kind
		item.amount = amount
		item.position = Vector3(0, 0, direction) * separation
	for i in range(flat.size(), get_child_count()):
		get_child(i).queue_free()

