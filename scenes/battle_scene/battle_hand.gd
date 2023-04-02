class_name BattleHand extends Node3D

@export var spacing: float = 2.5
@export var velocity: float = 15.0
@export var side: ZoneLocation.Side

var card_plane_scene: PackedScene = preload("res://objects/card_plane/card_plane.tscn")

@onready var group = $Group

func _process(delta: float):
	for i in range(group.get_child_count()):
		var child := group.get_child(i) as Node3D
		var ideal_pos := _get_ideal_pos(i)
		var span := ideal_pos - child.position
		var dir := span.normalized()
		var vel_move := dir * velocity * delta
		if vel_move.length_squared() > span.length_squared():
			vel_move = span
		child.position += vel_move

func add_card(card_instance: CardInstance):
	var card_plane = card_plane_scene.instantiate()
	card_plane.card = card_instance.card if card_instance else null
	
	var i := group.get_child_count()
	card_plane.location = ZoneLocation.new(side, ZoneLocation.Zone.Hand, i)
	
	assert(card_instance == null or card_plane.location.equals(card_instance.location))
	
	group.add_child(card_plane)
	
	card_plane.position = _get_ideal_pos(i)
	

func remove_card(slot: int):
	var idx = -1
	
	for i in range(group.get_child_count()):
		if group.get_child(i).location.slot == slot:
			idx = i
			break
	
	assert(idx != -1)
	
	var card_plane = group.get_child(idx)
	
	card_plane.queue_free()
	group.remove_child(card_plane)
	
	for i in range(group.get_child_count()):
		var c := group.get_child(i)
		if c.location.slot > slot:
			c.location.slot -= 1

func clear():
	while group.get_child_count() > 0:
		remove_card(group.get_child(0).location.slot)

func _get_ideal_pos(i: int) -> Vector3:
	var left_edge := (group.get_child_count() - 1) * -spacing / 2.0
	return Vector3(left_edge + i * spacing, 0, 0)
