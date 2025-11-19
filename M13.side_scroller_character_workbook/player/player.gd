extends CharacterBody2D

enum State {
	GROUND,
	JUMP,
	FALL
}

@export var acceleration := 700.0
@export var deceleration := 1400.0
@export var max_speed := 120.0
@export var jump_speed := 360.0
@export var air_acceleration := 500.0

var jump_gravity := 1200.0
var direction_x := 0.0
var current_state: State = State.GROUND

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D



func _ready() -> void:
	_transition_to_state(current_state)


func _physics_process(delta: float) -> void:
	direction_x = signf(Input.get_axis("move_left", "move_right"))

	match current_state:
		State.GROUND:
			process_ground_state(delta)
		State.JUMP:
			process_jump_state(delta)
		State.FALL:
			process_fall_state(delta)

	velocity.y += jump_gravity * delta
	move_and_slide()


func process_ground_state(delta: float) -> void:
	var is_moving := absf(direction_x) > 0.0
	if is_moving:
		velocity.x += acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)

		animated_sprite.flip_h = direction_x < 0.0
		animated_sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		animated_sprite.play("idle")

	if Input.is_action_just_pressed("jump"):
		_transition_to_state(State.JUMP)
	elif not is_on_floor():
		_transition_to_state(State.FALL)


func process_jump_state(delta: float) -> void:
	if direction_x != 0:
		velocity.x += air_acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		animated_sprite.flip_h = direction_x < 0.0

	if velocity.y >= 0:
		_transition_to_state(State.FALL)


func process_fall_state(delta: float) -> void:
	if direction_x != 0.0:
		velocity.x += air_acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		animated_sprite.flip_h = direction_x < 0.0

	if is_on_floor():
		_transition_to_state(State.GROUND)


func _transition_to_state(new_state: State) -> void:
	var previous_state := current_state
	current_state = new_state

	# Exit previous state
	match previous_state:
		pass

	# Enter new state
	match current_state:
		State.JUMP:
			velocity.y = -1.0 * jump_speed
			animated_sprite.play("jump")

		State.FALL:
			animated_sprite.play("fall")
