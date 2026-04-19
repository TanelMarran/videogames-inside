class_name ParkourGuy extends Node3D

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
	elif event is InputEventMouseMotion:
		
		follow_mouse(event)

func follow_mouse(event: InputEventMouseMotion):
	var screen_position: Vector2 = event.position
	var screen_position_normal: Vector2 = screen_position / get_viewport().get_visible_rect().size
	
	var world_position = get_viewport().get_camera_3d().project_position(screen_position, abs(position.z))
	
	global_position = world_position
	look_at(Vector3.ZERO)
