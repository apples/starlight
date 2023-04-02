class_name ClickTargetAgent extends Node

var last_click_target: ClickTarget

signal click_target_changed(click_target: ClickTarget)
signal confirmed(click_target: ClickTarget)
signal cancelled()

func _ready():
	ClickTargetManager.add_agent(self)
	tree_exiting.connect(func (): ClickTargetManager.remove_agent(self))

func confirm(click_target: ClickTarget):
	confirmed.emit(click_target)

func cancel():
	cancelled.emit()
