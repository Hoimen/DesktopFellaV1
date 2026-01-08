extends Node2D

@export var sprite_sleep: AnimatedSprite2D
@export var sprite_Animation1: AnimatedSprite2D
@export var sprite_Nutral1: AnimatedSprite2D
@export var sprite_Nutral2: AnimatedSprite2D
@export var sprite_Angry1: AnimatedSprite2D
@export var sprite_Angry2: AnimatedSprite2D
@export var sprite_Sad1: AnimatedSprite2D
@export var sprite_Sad2: AnimatedSprite2D
@export var sprite_Happy1: AnimatedSprite2D
@export var sprite_Happy2: AnimatedSprite2D
@export var sprite_Happy2M: AnimatedSprite2D
@export var sprite_Male: AnimatedSprite2D
@export var sprite_Female: AnimatedSprite2D
@export var sprite_Empty: AnimatedSprite2D
@export var sprite_Top: AnimatedSprite2D
@export var sprite_Left: AnimatedSprite2D
@export var sprite_Right: AnimatedSprite2D


func _ready():
	if sprite_sleep:
		sprite_sleep.play("Sleep")
	if sprite_Animation1:
		sprite_Animation1.play("Dizzy")
	if sprite_Nutral1:
		sprite_Nutral1.play("Talk Nutral F 1")
	if sprite_Nutral2:
		sprite_Nutral2.play("Talk Nutral F 2")
	if sprite_Angry1:
		sprite_Angry1.play("Talk Angry F 1")
	if sprite_Angry2:
		sprite_Angry2.play("Talk Angry F 2")
	if sprite_Sad1:
		sprite_Sad1.play("Talk Sad F 1")
	if sprite_Sad2:
		sprite_Sad2.play("Talk Sad F 2")
	if sprite_Happy1:
		sprite_Happy1.play("Talk Happy F 1")
	if sprite_Happy2:
		sprite_Happy2.play("Talk Happy F 2")
	if sprite_Male:
		sprite_Male.play("Cover M")
	if sprite_Female:
		sprite_Female.play("Cover F")
	if sprite_Empty:
		sprite_Empty.play("Placeholder")
	if sprite_Top:
		sprite_Top.play("Ouch top")
	if sprite_Left:
		sprite_Left.play("Ouch left")
	if sprite_Right:
		sprite_Right.play("Ouch right")
