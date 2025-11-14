extends CharacterBody2D

@export var acceleration := 700.0
@export var deceleration := 1400.0
@export var max_speed := 120.0
@export var jump_gravity := 1200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var direction_x := signf(Input.get_axis("move_left", "move_right"))
	
	var is_moving := absf(direction_x) > 0
	if is_moving:
		velocity.x += direction_x * acceleration * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		animated_sprite.flip_h = direction_x < 0.0
		animated_sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		animated_sprite.play("idle")
		
	velocity.y += jump_gravity * delta
		
	move_and_slide()
