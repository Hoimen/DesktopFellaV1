extends Node2D

# Exposed variables for inspector assignment
@export var target_sprite: Sprite2D
@export var target_window: Window


func _process(delta: float) -> void:
	if target_sprite and target_window:
		# Copy the window's height to the sprite's scale
		var window_height = target_window.size.y
		if target_sprite.texture:
			var sprite_height = target_sprite.texture.get_height()
			if sprite_height > 0:
				var scale_factor = window_height / sprite_height
				target_sprite.scale.y = scale_factor
