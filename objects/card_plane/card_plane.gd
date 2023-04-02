@tool
class_name CardPlane extends Node3D

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		refresh()

@export var show_card: bool = true:
	get:
		return show_card
	set(value):
		show_card = value
		refresh()

@export var is_tapped: bool = false:
	get:
		return is_tapped
	set(value):
		is_tapped = value
		refresh()

@export var tween_target: float = -90.0
@export var tween_duration: float = 0.5

var location: ZoneLocation = null:
	get:
		return location
	set(value):
		location = value
		refresh()

var _current_tap_tween_target: float = 0
var _current_tap_tween: Tween

var _toast_queue: Array[String] = []
var _toast_tween: Tween

@onready var subviewport := $SubViewport
@onready var card_render := $SubViewport/CardRender
@onready var sprite := $Sprite
@onready var click_target := %ClickTarget
@onready var action_root := %ActionRoot
@onready var toast_label := %ToastLabel as Label3D

func _ready():
	toast_label.visible = false
	refresh()

func _process(delta):
	if Engine.is_editor_hint():
		return
	
	if not _toast_tween and _toast_queue.size() > 0:
		toast_label.visible = true
		toast_label.position = Vector3.ZERO
		toast_label.text = _toast_queue[0]
		toast_label.modulate = Color(1,0.1,0.1,1)
		toast_label.outline_modulate = Color(0.2,0.1,0.1,1)
		_toast_queue.remove_at(0)
		_toast_tween = create_tween()\
			.set_trans(Tween.TRANS_ELASTIC)\
			.set_ease(Tween.EASE_IN_OUT)
		_toast_tween.tween_property(toast_label, "position", Vector3(0,0,3), 0.5)
		_toast_tween.finished.connect(func ():
			_toast_tween = create_tween()\
				.set_trans(Tween.TRANS_ELASTIC)\
				.set_ease(Tween.EASE_IN_OUT)
			var modulate_end := toast_label.modulate
			modulate_end.a = 0
			var outline_modulate_end := toast_label.outline_modulate
			outline_modulate_end.a = 0
			_toast_tween.tween_property(toast_label, "modulate", modulate_end, 0.25)
			_toast_tween.tween_property(toast_label, "outline_modulate", outline_modulate_end, 0.25)
			_toast_tween.finished.connect(func ():
				_toast_tween = null
				toast_label.visible = false
			)
		)

func refresh():
	if not is_inside_tree():
		return
	
	click_target.location = location
	
	if show_card:
		card_render.card = card
		subviewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
		sprite.visible = true
		
		if is_tapped and _current_tap_tween_target != tween_target:
			_refresh_tween_to(tween_target)
		elif !is_tapped and _current_tap_tween_target == tween_target:
			_refresh_tween_to(0)
	else:
		sprite.visible = false


func toast(str: String):
	_toast_queue.append(str)
	print("TOASTING %s" % str)


func reset():
	show_card = false
	card = null
	is_tapped = false
	if _current_tap_tween:
		_current_tap_tween.kill()
	sprite.rotation_degrees = Vector3(0,0,0)


func _refresh_tween_to(where: float):
	if _current_tap_tween:
		_current_tap_tween.kill()
	_current_tap_tween = create_tween()\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_IN_OUT)
	_current_tap_tween_target = tween_target
	_current_tap_tween.tween_property(sprite, "rotation_degrees", Vector3(0,0,where), tween_duration)


func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	if not click_target.enabled:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			click_target.confirm()


func _on_area_3d_mouse_entered():
	if click_target.enabled:
		click_target.make_current()
