# WindowFollower.gd
extends Node

@export var window_a : Window
@export var window_b : Window
@export var rich_text_label : RichTextLabel
@export var tail_sprite : Sprite2D
@export var vertical_offset : int = 0
@export var top_distance : int = 10
@export var bottom_distance : int = 10

func _process(_delta):
	if window_a and window_b and rich_text_label:
		# Calculate the text height
		var text_height = rich_text_label.get_content_height()
		
		# Calculate total desired height for window B (without tail yet)
		var total_height = top_distance + text_height + bottom_distance
		
		# Resize window B
		var new_size : Vector2i = window_b.size
		new_size.y = total_height
		window_b.size = new_size
		
		# Get tail height if tail sprite exists
		var tail_height = 0
		if tail_sprite and tail_sprite.texture:
			tail_height = int(tail_sprite.texture.get_height() * tail_sprite.scale.y)
		
		# Position window B above window A
		var pos_a : Vector2i = window_a.position
		var pos_b : Vector2i = pos_a
		pos_b.y = pos_a.y - window_b.size.y - tail_height - vertical_offset
		
		window_b.position = pos_b
		
		# Reposition RichTextLabel inside window B
		rich_text_label.position = Vector2(0, top_distance)
		
		# Position the tail sprite below window B
		if tail_sprite and tail_sprite.texture:
			# Convert Vector2i → Vector2 properly
			var window_b_pos_v2 = Vector2(window_b.position)
			
			var tail_pos = window_b_pos_v2 + Vector2(
				(window_b.size.x / 2.0) - (tail_sprite.texture.get_width() * tail_sprite.scale.x / 2.0),
				window_b.size.y
			)
			tail_sprite.global_position = tail_pos
