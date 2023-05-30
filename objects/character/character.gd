extends CharacterBody2D

@export var move_speed: float = 200.0
@export var interpolate_sprite: bool = true

var _input_dir: Vector2

var _sprite_interpolation_tween: Tween

@onready var sprite = %Sprite
@onready var sprite_anchor = %SpriteAnchor

func _process(delta):
	_input_dir = Vector2()
	if Input.is_action_pressed("left"):
		_input_dir.x -= 1
	if Input.is_action_pressed("right"):
		_input_dir.x += 1
	if Input.is_action_pressed("up"):
		_input_dir.y -= 1
	if Input.is_action_pressed("down"):
		_input_dir.y += 1
	
	if Input.is_action_just_pressed("left"):
		sprite.flip_h = true
	if Input.is_action_just_pressed("right"):
		sprite.flip_h = false
	
	if velocity != Vector2() or _input_dir != Vector2():
		sprite.play("walk")
	else:
		sprite.play("default")

func _physics_process(delta):
	
	velocity = _input_dir * move_speed
	
	var sprite_start = sprite_anchor.global_position
	
	move_and_slide()
	
	var sprite_end = self.global_position
	
	if interpolate_sprite:
		sprite_anchor.global_position = sprite_start
		
		if _sprite_interpolation_tween:
			_sprite_interpolation_tween.kill()
		_sprite_interpolation_tween = create_tween()
		_sprite_interpolation_tween.tween_property(sprite_anchor, "global_position", sprite_end, delta)
		
		_sprite_interpolation_tween.finished.connect(func (): self._sprite_interpolation_tween = null)
	

