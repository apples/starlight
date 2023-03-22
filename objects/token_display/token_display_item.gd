extends Node3D

var token_dir := "res://icons/tokens/"

@onready var sprite = $Sprite3D
@onready var label = $Label3D


var kind: BattleState.TokenType:
	get:
		return kind
	set(value):
		kind = value
		var key = BattleState.TokenType.find_key(kind)
		sprite.texture = load(token_dir.path_join("%s.png" % key.to_lower()))

var amount: int:
	get:
		return amount
	set(value):
		amount = value
		label.text = "x%s" % amount
