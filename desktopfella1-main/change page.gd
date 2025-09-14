extends Node

@export var my_button: Button
@export var control_to_show: Control
@export var control_to_hide: Control

func _ready():
	if my_button:
		my_button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	if control_to_show:
		control_to_show.visible = true
	if control_to_hide:
		control_to_hide.visible = false
