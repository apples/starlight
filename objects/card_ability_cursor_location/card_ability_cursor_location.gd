extends CursorLocation

var track_control: Control:
	get:
		return track_control
	set(value):
		track_control = value

func _process(delta):
	if not track_control:
		return
	self.position = track_control.global_position
	self.size = track_control.size / self.scale
