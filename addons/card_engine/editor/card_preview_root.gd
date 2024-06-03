@tool
extends Control

const ZOOM_LEVELS = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]

var _zoom_idx := 1

@onready var card_preview_container: MarginContainer = %CardPreviewContainer
@onready var fit_check_button: CheckButton = $FitCheckButton

func _ready() -> void:
	resized.connect(_on_resized)
	fit_check_button.toggled.connect(_on_fit_check_button_toggled)
	update_size()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_idx = clampi(_zoom_idx + 1, 0, ZOOM_LEVELS.size())
			fit_check_button.button_pressed = false
			update_size()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_idx = clampi(_zoom_idx - 1, 0, ZOOM_LEVELS.size())
			fit_check_button.button_pressed = false
			update_size()
	if not fit_check_button.button_pressed:
		if event is InputEventMouseMotion:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				card_preview_container.position += event.relative
				card_preview_container.position = card_preview_container.position.clamp(
					size / 2.0 - card_preview_container.size,
					size / 2.0)


func update_size() -> void:
	if fit_check_button.button_pressed:
		card_preview_container.size = size
		card_preview_container.position = Vector2.ZERO
	else:
		var center = card_preview_container.get_rect().get_center()
		card_preview_container.size = CardDatabase.config.card_size_pixels * ZOOM_LEVELS[_zoom_idx]
		var center2 = card_preview_container.get_rect().get_center()
		card_preview_container.position += center - center2
		card_preview_container.position = card_preview_container.position.clamp(
			size / 2.0 - card_preview_container.size,
			size / 2.0)


func _on_resized() -> void:
	update_size()

func _on_fit_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_zoom_idx = 1
	update_size()
