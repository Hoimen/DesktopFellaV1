extends Node


@export var toggle_button: Button
@export var target_node_1: Node
@export var target_node_2: Node

func _ready() -> void:
	if toggle_button:
		toggle_button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if target_node_1:
		target_node_1.visible = not target_node_1.visible
	if target_node_2:
		target_node_2.visible = not target_node_2.visible
