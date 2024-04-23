class_name ClickTarget extends Node

signal confirmed(click_target: ClickTarget)
signal made_current(click_target: ClickTarget)
signal enabled_changed(click_target: ClickTarget, enabled: bool)

@export var custom_tag: String = ""

var group: ClickTargetGroup

var location: ZoneLocation = null

var temporary_disable: bool = false

var enabled: bool = true:
	get:
		return enabled if not temporary_disable else false
	set(value):
		if enabled != value:
			enabled = value
			show_highlight(enabled)
			enabled_changed.emit(self, enabled)

var is_current: bool = false:
	get:
		return is_current
	set(value):
		is_current = value
		if cursor_sprite:
			cursor_sprite.visible = is_current

@onready var cursor_sprite: Node
@onready var highlight: Node

func _ready():
	cursor_sprite = get_node_or_null("CursorSprite")
	if cursor_sprite:
		cursor_sprite.visible = is_current
	
	highlight = get_node_or_null("Highlight")
	show_highlight(enabled)
	
	var parent = get_parent()
	while parent != null:
		if parent is ClickTargetGroup:
			group = parent
			break
		parent = parent.get_parent()
	
	if group:
		group.add_target(self)
		tree_exiting.connect(_on_tree_exiting)
	else:
		queue_free()

func confirm():
	confirmed.emit(self)

func make_current():
	assert(enabled)
	# we expect the ClickTargetManager to set is_current via this signal
	made_current.emit(self)

func show_highlight(on: bool) -> void:
	if not highlight:
		return
	highlight.visible = on
	if "modulate" in highlight:
		highlight.modulate = Color.CYAN

func _on_tree_exiting():
	group.remove_target(self)
	group = null
