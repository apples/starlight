extends Label

var _tween: Tween

func animate():
	if _tween:
		_tween.kill()
	visible_ratio = 0
	_tween = create_tween()
	_tween.tween_property(self, "visible_ratio", 1.0, 0.25)
