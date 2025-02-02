@tool
extends CardAbilityEffect

@export var on_heads: CardAbilityEffect
@export var on_tails: CardAbilityEffect

# Returns the damage as text to display on the card face
# Only used for Attacks
func get_attack_damage() -> String:
	var h_str := on_heads.get_attack_damage() if on_heads else ""
	var t_str := on_tails.get_attack_damage() if on_tails else ""
	if not h_str and not t_str:
		return ""
	if not h_str or not t_str or not h_str.is_valid_int() or not t_str.is_valid_int():
		return "?"
	var h_int := int(h_str)
	var t_int := int(t_str)
	if h_int < t_int:
		return h_str + "+"
	else:
		return t_str + "+"

# The task which will perform the effect
class Task extends CardTask:
	
	# Start of effect execution
	func start() -> void:
		# Print some debug info
		info("not implemented")
		
		fail()
