extends Node

@export var animated_sprite: AnimatedSprite2D
@export var hide_when_held: Node

@export var content_root: Node
@export var drag_panel_container: PanelContainer
@export var drag_when_held_panel: PanelContainer
@export var text_window: Window
@export var window_a: Window


const MOVEMENT_THRESHOLD := 5.0
const INACTIVITY_TIMEOUT := 0.3
const GRAVITY := 5000.0
const MAX_FALL_SPEED := 3000.0

@export var min_window_width: int = 400

var timer := 0.0
var last_mouse_pos := Vector2.ZERO
var time_since_last_move := 0.0
var fall_speed := 0.0
var is_falling := false
var is_holding_window := false

var original_window_size: Vector2
var drag_window_center: Vector2
var drag_offset_to_center: Vector2

var playing_directional := false

func _ready():
	_stop_animation()
	if animated_sprite:
		animated_sprite.visible = false
	if hide_when_held:
		hide_when_held.visible = true
	last_mouse_pos = Vector2(DisplayServer.mouse_get_position())

	var window = get_window()
	original_window_size = Vector2(window.size)
	drag_window_center = Vector2(window.position) + window.size * 0.5
	drag_offset_to_center = Vector2.ZERO

	if drag_panel_container:
		drag_panel_container.gui_input.connect(_on_drag_panel_gui_input)

func _on_drag_panel_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_holding_window = true
			var window = get_window()
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			drag_window_center = Vector2(window.position) + window.size * 0.5
			drag_offset_to_center = mouse_pos - drag_window_center
		else:
			is_holding_window = false

func _process(delta):
	timer += delta
	time_since_last_move += delta

	var mouse_pos := Vector2(DisplayServer.mouse_get_position())
	var window = get_window()
	var usable_rect := DisplayServer.screen_get_usable_rect()

	if is_holding_window:
		drag_window_center = mouse_pos - drag_offset_to_center
		var half_width = window.size.x * 0.5
		drag_window_center.x = clamp(
			drag_window_center.x,
			usable_rect.position.x + half_width,
			usable_rect.position.x + usable_rect.size.x - half_width
		)

		window.size.x = min_window_width
		window.position = Vector2i((drag_window_center - window.size * 0.5).floor())

		var delta_pos = mouse_pos - last_mouse_pos
		if delta_pos.length() >= MOVEMENT_THRESHOLD:
			_play_direction_animation(delta_pos)
			time_since_last_move = 0.0
		else:
			if time_since_last_move >= INACTIVITY_TIMEOUT:
				_play_animation("normal_hold")
				playing_directional = false

		fall_speed = 0.0
		is_falling = false

		_keep_window_on_screen(window, usable_rect)
		_update_drag_when_held_shift(window)
	else:
		var center_x = window.position.x + window.size.x * 0.5
		window.size.x = original_window_size.x
		window.position.x = int(center_x - window.size.x * 0.5)

		_keep_window_on_screen(window, usable_rect)
		_update_drag_when_held_shift(window)

		if window.position.y + window.size.y < usable_rect.position.y + usable_rect.size.y:
			fall_speed = min(fall_speed + GRAVITY * delta, MAX_FALL_SPEED)
			var new_y = window.position.y + int(fall_speed * delta)
			new_y = clamp(new_y, usable_rect.position.y, usable_rect.position.y + usable_rect.size.y - window.size.y)
			window.position.y = new_y
			is_falling = true
			_play_animation("held_down")
		else:
			window.position.y = usable_rect.position.y + usable_rect.size.y - window.size.y
			fall_speed = 0.0
			is_falling = false
			_stop_animation()

	if time_since_last_move >= INACTIVITY_TIMEOUT and not is_falling and not is_holding_window:
		_stop_animation()

	# Sprite visibility
	if is_holding_window or is_falling:
		if animated_sprite:
			animated_sprite.visible = true
	else:
		if animated_sprite:
			animated_sprite.visible = false

	_update_content_visibility()
	last_mouse_pos = mouse_pos

func _keep_window_on_screen(window, usable_rect):
	if window.position.x < usable_rect.position.x:
		window.position.x = usable_rect.position.x

	var right = window.position.x + window.size.x
	if right > usable_rect.position.x + usable_rect.size.x:
		window.position.x = usable_rect.position.x + usable_rect.size.x - window.size.x

func _update_drag_when_held_shift(window):
	if not drag_when_held_panel:
		return
	var lost_width = original_window_size.x - window.size.x
	drag_when_held_panel.position.x = -(lost_width * 0.5)

func _play_direction_animation(delta_pos: Vector2):
	if not animated_sprite:
		return

	playing_directional = true

	if abs(delta_pos.x) > abs(delta_pos.y):
		if delta_pos.x > 0:
			_play_animation("held_right")
		else:
			_play_animation("held_left")
	else:
		if delta_pos.y > 0:
			_play_animation("held_down")
		else:
			_play_animation("held_up")

func _play_animation(name: String):
	if animated_sprite:
		if animated_sprite.animation != name or not animated_sprite.is_playing():
			animated_sprite.play(name)

func _stop_animation():
	if animated_sprite:
		animated_sprite.stop()
		animated_sprite.visible = false
	playing_directional = false

func _update_content_visibility():
	if not content_root:
		return

	var is_animating := animated_sprite and animated_sprite.visible and animated_sprite.is_playing()
	content_root.visible = not is_animating

	if hide_when_held:
		hide_when_held.visible = not is_animating

	if text_window:
		# Base rule: hide while dragging/falling
		var should_show := not (is_holding_window or is_falling)

		# If "Window A" exists, also require it to be visible
		if window_a:
			# Guard for both property and method (works across Godot 4.x)
			var a_visible := true
			if "visible" in window_a:
				a_visible = a_visible and window_a.visible
			if "is_visible" in window_a:
				a_visible = a_visible and window_a.is_visible()

			should_show = should_show and a_visible

		if should_show:
			text_window.show()
		else:
			text_window.hide()
