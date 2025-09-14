extends Node2D

@export var sprite_sleep: AnimatedSprite2D
#@export var sprite_dizzy: AnimatedSprite2D

func _ready():
	if sprite_sleep:
		sprite_sleep.play("Sleep")
	#if sprite_dizzy:
		#sprite_dizzy.play("Dizzy")
