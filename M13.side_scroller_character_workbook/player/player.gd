extends CharacterBody2D

enum State {
	GROUND,
	JUMP,
	DOUBLE_JUMP,
	FALL
}

const MAX_JUMPS := 2

var jump_count := 0

@export var acceleration := 700.0
@export var deceleration := 1400.0
@export var max_speed := 120.0
@export var air_acceleration := 500.0

@export var max_fall_speed := 250.0

@export_category("Jump")
@export_range(10.0, 200.0) var jump_height := 50.0
@export_range(0.1, 1.5) var jump_time_to_peak := 0.37
@export_range(0.1, 1.5) var jump_time_to_descent := 0.2
@export_range(50.0, 200.0) var jump_horizontal_distance := 80.0
@export_range(5.0, 50.0) var jump_cut_divider := 15.0

@export_category("Double Jump")
@export_range(10.0, 200.0) var double_jump_height := 30.0
@export_range(0.1, 1.5) var double_jump_time_to_peak := 0.3
@export_range(0.1, 1.5) var double_jump_time_to_descent := 0.25

var direction_x := 0.0
var current_gravity := 0.0
var current_state: State = State.GROUND

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D

@onready var jump_speed := calculate_jump_speed(jump_height, jump_time_to_peak)
@onready var jump_gravity := calculate_jump_gravity(jump_height, jump_time_to_peak)
@onready var fall_gravity := calculate_fall_gravity(jump_height, jump_time_to_descent)
@onready var jump_horizontal_velocity := calculate_horizontal_speed(jump_horizontal_distance, jump_time_to_peak, jump_time_to_descent)

@onready var double_jump_speed := calculate_jump_speed(double_jump_height, double_jump_time_to_peak)
@onready var double_jump_gravity := calculate_jump_gravity(double_jump_height, double_jump_time_to_peak)
@onready var double_jump_fall_gravity := calculate_fall_gravity(double_jump_height, double_jump_time_to_descent)

@onready var coyote_timer := Timer.new()

func _ready() -> void:
	_transition_to_state(current_state)
	coyote_timer.wait_time = 0.1
	coyote_timer.one_shot = true
	add_child(coyote_timer)

func play_tween_jump() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.15, 0.86), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2(0.86, 1.15), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2.ONE, 0.15)

func play_tween_touch_ground() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.1, 0.9), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2(0.9, 1.1), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2.ONE, 0.1)

func _physics_process(delta: float) -> void:
	direction_x = signf(Input.get_axis("move_left", "move_right"))

	match current_state:
		State.GROUND:
			process_ground_state(delta)
		State.JUMP:
			process_jump_state(delta)
		State.FALL:
			process_fall_state(delta)
		State.DOUBLE_JUMP:
			process_double_jump_state(delta)

	velocity.y += current_gravity * delta
	velocity.y = minf(velocity.y, max_fall_speed)
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
		velocity.x = clampf(velocity.x, -jump_horizontal_velocity, jump_horizontal_velocity)
		animated_sprite.flip_h = direction_x < 0.0

	if Input.is_action_just_released("jump"):
		var jump_cut_speed := jump_speed / jump_cut_divider
		if velocity.y < 0.0 and velocity.y < jump_cut_speed:
			velocity.y = jump_cut_speed

	if velocity.y >= 0:
		_transition_to_state(State.FALL)
	elif Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		_transition_to_state(State.DOUBLE_JUMP)

func process_fall_state(delta: float) -> void:
	if direction_x != 0.0:
		velocity.x += air_acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -jump_horizontal_velocity, jump_horizontal_velocity)
		animated_sprite.flip_h = direction_x < 0.0

	if Input.is_action_just_pressed("jump"): 
		if not coyote_timer.is_stopped():
			_transition_to_state(State.JUMP)
		elif jump_count < MAX_JUMPS:
			_transition_to_state(State.DOUBLE_JUMP)

	if is_on_floor():
		_transition_to_state(State.GROUND)

func process_double_jump_state(delta: float) -> void:
	if direction_x != 0.0:
		velocity.x += air_acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -jump_horizontal_velocity, jump_horizontal_velocity)
		animated_sprite.flip_h = direction_x < 0.0
		
	if velocity.y >= 0.0:
		_transition_to_state(State.FALL)

func _transition_to_state(new_state: State) -> void:
	var previous_state := current_state
	current_state = new_state

	# Exit previous state
	match previous_state:
		State.FALL:
			coyote_timer.stop()

	# Enter new state
	match current_state:
		State.JUMP:
			velocity.y = jump_speed
			current_gravity = jump_gravity
			velocity.x = direction_x * jump_horizontal_velocity
			jump_count = 1
			animated_sprite.play("jump")
			play_tween_jump()

		State.DOUBLE_JUMP:
			velocity.y = double_jump_speed
			current_gravity = double_jump_gravity
			velocity.x = direction_x * jump_horizontal_velocity
			jump_count = MAX_JUMPS
			animated_sprite.play("jump")
			play_tween_jump()
			
		State.FALL:
			if jump_count == MAX_JUMPS:
				current_gravity = double_jump_gravity
			else:
				current_gravity = fall_gravity
			animated_sprite.play("fall")
			
			if previous_state == State.GROUND:
				coyote_timer.start()
			
		State.GROUND:
			jump_count = 0
			if previous_state == State.FALL:
				play_tween_touch_ground()

func calculate_jump_speed (height: float, time_to_peak: float) -> float:
	return (-2.0 * height) / time_to_peak
	
func calculate_jump_gravity (height: float, time_to_peak: float) -> float:
	return (2.0 * height) / pow(time_to_peak, 2.0)

func calculate_fall_gravity(height: float, time_to_descent: float) -> float:
	return (2.0 * height) / pow(time_to_descent, 2.0)

func calculate_horizontal_speed(distance: float, time_to_peak: float, time_to_descent: float) -> float:
	return distance / (time_to_descent + time_to_peak)
