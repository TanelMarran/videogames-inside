class_name ParkourGuy extends Node3D

@export var animation_player: AnimationPlayer
@export var animation_tree: AnimationTree
@export var look_at_camera: bool

@export_group("Buffering")
@export var buffer_time: float = 0.5
var _previously_held_button_amount: int = 0
var _pose_update_buffer: int = 0

@export_group("Acceleration")
@export var acceleration_measure_size: int = 10
@export var acceleration_curve: Curve
@export_range(0, 100, 1) var acceleration_normalize_scale: float = 10
@export_range(0, 100, 1) var acceleration_strength: float = 10
@export_range(0, 1, .1) var acceleration_min_speed: float = .8
@export_range(1, 100, .1) var acceleration_max_speed: float = 10

@onready var _previous_position: Vector3 = global_position
var _previous_acceleration: Array[Vector3] = []
var acceleration: Vector3 = Vector3.ZERO

var _blend_up_down = 0.5:
	set(value):
		_blend_up_down = value
		if animation_tree:
			animation_tree.set('parameters/up_down/blend_amount', value)

var _blend_not_pressed = 1.0:
	set(value):
		_blend_not_pressed = value
		if animation_tree:
			animation_tree.set('parameters/non_pressed/blend_amount', value)

var _blend_left_right = .5:
	set(value):
		_blend_left_right = value
		if animation_tree:
			animation_tree.set('parameters/left_right/seek_request', value)

var _blend_directional_influence: float = 0.5:
	set(value):
		_blend_directional_influence = value
		if animation_tree:
			animation_tree.set('parameters/directional_influence/blend_amount', value)

var _action_map: Dictionary = {
	'key_up': 'up',
	'key_down': 'down'
}

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseMotion:
		follow_mouse(event)
	
func _process(delta):
	_pose_update_buffer = max(0, _pose_update_buffer - delta)
	var key_right: int = (1 if Input.is_action_pressed("key_right") else 0)
	var key_left: int = (1 if Input.is_action_pressed("key_left") else 0)
	var key_down: int = (1 if Input.is_action_pressed("key_down") else 0)
	var key_up: int = (1 if Input.is_action_pressed("key_up") else 0)
	var total_keys_pressed: float = key_right + key_left + key_up + key_down
	
	
	if (total_keys_pressed != _previously_held_button_amount):
		_pose_update_buffer = buffer_time
		
	if (_pose_update_buffer == 0):
		update_pose()
		
	_previously_held_button_amount = total_keys_pressed
	
func update_pose():
	var key_right: int = (1 if Input.is_action_pressed("key_right") else 0)
	var key_left: int = (1 if Input.is_action_pressed("key_left") else 0)
	var key_down: int = (1 if Input.is_action_pressed("key_down") else 0)
	var key_up: int = (1 if Input.is_action_pressed("key_up") else 0)
	var total_keys_pressed: float = key_right + key_left + key_up + key_down
	
	_blend_up_down = (((key_down - key_up) + 1) / 2.0)
	_blend_left_right = (((key_right - key_left) + 1) / 2.0) * 2
	_blend_not_pressed = 1 if total_keys_pressed == 0 else 0
	_blend_directional_influence = (((((key_right + key_left - key_up - key_down) / (total_keys_pressed))) + 1) / 2) if total_keys_pressed > 0 else .5
	
func follow_mouse(event: InputEventMouseMotion):
	var screen_position: Vector2 = event.position
	var screen_position_normal: Vector2 = screen_position / get_viewport().get_visible_rect().size
	
	var world_position = get_viewport().get_camera_3d().project_position(screen_position, abs(position.z))
	
	global_position = world_position
	if look_at_camera:
		look_at(Vector3.ZERO)
	else:
		rotation = Vector3.ZERO;

func _physics_process(delta):
	update_acceleration(_previous_position, global_position, delta)
	_previous_position = global_position
	
func update_acceleration(prev_pos: Vector3, current_pos: Vector3, delta: float) -> void:
	_previous_acceleration.append((current_pos - prev_pos) / delta)
	
	if (len(_previous_acceleration) > acceleration_measure_size):
		_previous_acceleration.pop_front()
	if (len(_previous_acceleration) > 0):
		var _unnormalized_acceleration = _previous_acceleration.reduce(func(accum, value): return accum + value, Vector3.ZERO) / (len(_previous_acceleration) as float)
		acceleration = (_unnormalized_acceleration / acceleration_normalize_scale).clamp(Vector3.ONE * -1.0, Vector3.ONE * 1.0)
		Global.scroll_speed += acceleration_curve.sample(abs(acceleration.x)) * sign(acceleration.x) * acceleration_strength
		Global.scroll_speed = clamp(Global.scroll_speed, acceleration_min_speed, acceleration_max_speed)
