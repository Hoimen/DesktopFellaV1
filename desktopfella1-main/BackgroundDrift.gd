extends Node

@export var background: Sprite2D

@export var max_x: float = 100.0    # left/right drift range from start
@export var max_y: float = 50.0     # up/down drift range from start
@export var speed: float = 50.0     # constant drift speed

# Mouse "push" settings
@export var push_strength: float = 0.08   # how much each mouse move nudges it
@export var max_push_offset: float = 20.0 # max pixels of mouse-based offset
@export var push_decay: float = 5.0       # how fast it recenters when mouse stops

var _start_position: Vector2
var _drift_position: Vector2
var _velocity: Vector2

var _mouse_offset: Vector2 = Vector2.ZERO
var _last_mouse_pos: Vector2
var _mouse_initialized := false


func _ready():
	if background == null:
		push_warning("Background Sprite2D not assigned!")
		return

	randomize()

	_drift_position = background.position
	_start_position = _drift_position

	# Constant-speed initial drift direction
	var angle = randf_range(0.0, TAU)
	_velocity = Vector2(cos(angle), sin(angle)).normalized() * speed


func _process(delta):
	if background == null:
		return

	# --- 1) CONSTANT DRIFT + BOUNCE (no mouse stuff here) ---

	var pos = _drift_position
	pos += _velocity * delta

	# Bounce horizontally
	if pos.x < _start_position.x - max_x:
		pos.x = _start_position.x - max_x
		_velocity.x = abs(_velocity.x)
	elif pos.x > _start_position.x + max_x:
		pos.x = _start_position.x + max_x
		_velocity.x = -abs(_velocity.x)

	# Bounce vertically
	if pos.y < _start_position.y - max_y:
		pos.y = _start_position.y - max_y
		_velocity.y = abs(_velocity.y)
	elif pos.y > _start_position.y + max_y:
		pos.y = _start_position.y + max_y
		_velocity.y = -abs(_velocity.y)

	_drift_position = pos

	# --- 2) MOUSE "PUSH" OFFSET (based on mouse movement, not position) ---

	var mouse_pos = get_viewport().get_mouse_position()

	if not _mouse_initialized:
		_last_mouse_pos = mouse_pos
		_mouse_initialized = true

	var mouse_delta = mouse_pos - _last_mouse_pos
	_last_mouse_pos = mouse_pos

	# If the mouse moved, push a bit in that direction
	if mouse_delta.length() > 0.1:
		_mouse_offset += mouse_delta * push_strength

		# Clamp how far it can be pushed
		if _mouse_offset.length() > max_push_offset:
			_mouse_offset = _mouse_offset.normalized() * max_push_offset

	# Always decay back toward center (so when mouse stops, offset fades out)
	_mouse_offset = _mouse_offset.lerp(Vector2.ZERO, delta * push_decay)

	# --- 3) FINAL POSITION = DRIFT + PUSH OFFSET ---

	background.position = _drift_position + _mouse_offset
