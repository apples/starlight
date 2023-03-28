class_name CardCursorAgent extends Node

var last_location: Node

signal cursor_location_changed(cursor_location: CursorLocation)
signal confirmed(cursor_location: CursorLocation)
signal cancelled()

func _ready():
	CardCursor.add_agent(self)

func confirm(cursor_location: CursorLocation):
	confirmed.emit(cursor_location)

func cancel():
	cancelled.emit()
