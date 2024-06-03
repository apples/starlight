@tool
extends Label

func _ready() -> void:
	refresh()

func refresh() -> void:
	get_parent().refresh()
