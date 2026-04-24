extends Node

@export_range(0, 100, 0.01) var scroll_reset_speed: float = .1
@export var resting_scroll_speed = .8;
var scroll_speed: float = 1.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	Global.scroll_speed += (resting_scroll_speed - Global.scroll_speed) * scroll_reset_speed * delta
