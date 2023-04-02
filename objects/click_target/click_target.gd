class_name ClickTarget extends Node

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
			enabled_changed.emit(self, enabled)

var is_current: bool = false:
	get:
		return is_current
	set(value):
		is_current = value
		self.visible = is_current

signal confirmed(click_target: ClickTarget)
signal made_current(click_target: ClickTarget)
signal enabled_changed(click_target: ClickTarget, enabled: bool)

func _ready():
	self.visible = is_current
	
	var parent = get_parent()
	while parent != null:
		if parent is ClickTargetGroup:
			group = parent
			break
		parent = parent.get_parent()
	
	if not group:
		group = ClickTargetManager.default_group
	
	group.add_target(self)
	
	tree_exiting.connect(_on_tree_exiting)

func confirm():
	confirmed.emit(self)

func make_current():
	assert(enabled)
	made_current.emit(self)

func _on_tree_exiting():
	group.remove_target(self)
	group = null
