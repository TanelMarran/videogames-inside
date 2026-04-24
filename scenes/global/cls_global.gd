extends Node

@export_range(0, 100, 0.01) var scroll_reset_speed: float = .1
var scroll_speed: float = 1.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	Global.scroll_speed += (1 - Global.scroll_speed) * scroll_reset_speed * delta
	print(Global.scroll_speed)
