class_name BattleHand extends Node3D

@export var spacing: float = 2.5
@export var velocity: float = 15.0

func _process(delta: float):
	var left_edge := (get_child_count() - 1) * -spacing / 2.0
	for i in range(get_child_count()):
		var child := get_child(i) as Node3D
		var ideal_pos := Vector3(left_edge + i * spacing, 0, 0)
		var span := ideal_pos - child.position
		var dir := span.normalized()
		var vel_move := dir * velocity * delta
		if vel_move.length_squared() > span.length_squared():
			vel_move = span
		child.position += vel_move
