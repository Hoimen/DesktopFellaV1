extends Node

@export var label: Label              # <-- You assign this in the inspector
@export var amplitude: float = 10.0   # How far up/down it moves
@export var duration: float = 1.0     # Time to move one direction

var _start_position: Vector2

func _ready():
	if label == null:
		push_warning("Label is not assigned!")
		return

	_start_position = label.position
	_start_bob()


func _start_bob():
	# Reset to starting position
	label.position = _start_position

	var tween = create_tween()
	tween.set_loops()  # Loop forever

	# Move down
	tween.tween_property(
		label,
		"position:y",
		_start_position.y + amplitude,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Move up
	tween.tween_property(
		label,
		"position:y",
		_start_position.y - amplitude,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
