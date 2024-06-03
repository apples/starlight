@tool
extends ScrollContainer

const ZOOM_LEVELS = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

var _zoom_idx := 1

@onready var card_preview_container: MarginContainer = %CardPreviewContainer
@onready var fit_check_button: CheckButton = $"../FitCheckButton"

func _ready() -> void:
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
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			get_h_scroll_bar().value -= event.relative.x
			get_v_scroll_bar().value -= event.relative.y

func update_size() -> void:
	if fit_check_button.button_pressed:
		card_preview_container.custom_minimum_size = Vector2.ZERO
		card_preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		get_h_scroll_bar().value = 0
		get_v_scroll_bar().value = 0
	else:
		card_preview_container.custom_minimum_size = CardDatabase.config.card_size_pixels * ZOOM_LEVELS[_zoom_idx]
		card_preview_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_preview_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size += Vector2.ONE


func _on_fit_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_zoom_idx = 1
	update_size()
