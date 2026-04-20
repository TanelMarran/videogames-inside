class_name ParkourGuy extends Node3D

@export var animation_player: AnimationPlayer

var _action_map: Dictionary = {
	'key_up': 'up',
	'key_down': 'down'
}

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseMotion:
		follow_mouse(event)
	
func _process(delta):
	var action_mapped: bool = false
	for action in _action_map.keys():
		if Input.is_action_pressed(action):
			animation_player.play(_action_map.get(action))
			action_mapped = true
			break
			
	if !action_mapped:
		animation_player.play('rest')
	
func follow_mouse(event: InputEventMouseMotion):
	var screen_position: Vector2 = event.position
	var screen_position_normal: Vector2 = screen_position / get_viewport().get_visible_rect().size
	
	var world_position = get_viewport().get_camera_3d().project_position(screen_position, abs(position.z))
	
	global_position = world_position
	look_at(Vector3.ZERO)
