@tool
extends Container

var card_plane_control_scene: PackedScene

@onready var card_plane_control
@onready var count_label = %CountLabel
@onready var card_plane_container = %CardPlaneContainer
@onready var button_minus = %ButtonMinus
@onready var button_plus = %ButtonPlus

signal change_count(id: int, amount: int)
signal right_clicked(id)

var id: int

var card: Resource = null:
	get:
		return card
	set(value):
		card = value
		if card_plane_control:
			card_plane_control.card = card

var count: int = 0:
	get:
		return count
	set(value):
		count = value
		if count_label:
			count_label.text = str(count)

var zoom: float = 1:
	get:
		return zoom
	set(value):
		zoom = value
		if card_plane_container:
			card_plane_container.custom_minimum_size = Vector2(zoom, zoom) * CardDatabase.config.card_size_pixels

func _ready():
	card_plane_control_scene = CardDatabase.config.card_control
	card_plane_control = card_plane_control_scene.instantiate()
	card_plane_control.card = card
	count_label.text = str(count)
	card_plane_container.add_child(card_plane_control)
	card_plane_container.custom_minimum_size = Vector2(zoom, zoom) * CardDatabase.config.card_size_pixels


func _on_button_minus_pressed():
	change_count.emit(id, -1)


func _on_button_plus_pressed():
	change_count.emit(id, +1)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(id)
