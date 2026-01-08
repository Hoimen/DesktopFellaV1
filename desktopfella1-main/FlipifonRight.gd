extends Container

@export var animation: AnimatedSprite2D
@export var window: Window
@export_range(0.0, 1.0, 0.01) var right_side_threshold: float = 0.6

func _process(_delta):
	if not animation or not window:
		return

	var window_position = window.position
	var window_size = window.size
	var screen_index = window.get_current_screen()
	var screen_size = DisplayServer.screen_get_size(screen_index)

	var window_center_x = window_position.x + (window_size.x / 2.0)

	# Flip horizontally if the window is on the right side of the screen
	animation.flip_h = window_center_x > screen_size.x * right_side_threshold
