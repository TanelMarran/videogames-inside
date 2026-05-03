@tool
class_name Looper extends Node3D

@export_group("Dimensions & Speed")
@export var repeat_vector: Vector3 = Vector3(1, 0, 0)
@export var repeat_count: int = 3:
	set(value):
		repeat_count = value
		_create_anchors()
@export var scroll_speed: float
			
var _has_oneshot: bool = false

@export_group("Randomness")
@export_range(0, 1, 0.01) var prop_chance: float = 1
@export var oneshot: bool = false:
	set(value):
		oneshot = value
		if oneshot:
			_has_oneshot = false
@export var seed: int

@export_group("Debug")
@export_tool_button('Reload', 'Reload') var reload_button_click: Callable = on_reload_button_click

var _anchors: Array[Node3D] = []

var _reference_nodes: Array[Node3D] =  []
var _copy_nodes: Array[Node3D] = []

var _distance_scrolled: float = 0

var valid_copy_of_values: Array[String] = []:
	get():
		return _reference_nodes.map(func(node): node.name)

signal references_update

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	references_update.connect(_on_references_update)
	_reference_nodes.assign(get_children().filter( func(item): 
		var is_3d: bool = item is Node3D && !item.has_meta('anchor') && !item.has_meta('copy_of')
		if is_3d:
			item.visible = false
		return is_3d
	))
	_create_anchors()

func on_reload_button_click(): 
	_reference_nodes = []
	_reference_nodes.assign(get_children().filter( func(item): 
		var is_3d: bool = item is Node3D && !item.has_meta('anchor') && !item.has_meta('copy_of')
		if is_3d:
			item.visible = false
		return is_3d
	))
	_create_anchors()

func _on_child_entered_tree(node: Node3D) -> void:
	if node as Node3D:
		if !_reference_nodes.has(node) && !node.has_meta('anchor') && !node.has_meta('copy_of'):
			_reference_nodes.append(node)
			node.visible = false
			node.set_meta('reference', true)
			references_update.emit()

func _on_child_exiting_tree(node: Node) -> void:
	if node as Node3D:
		if _reference_nodes.has(node):
			_reference_nodes.erase(node)
			node.visible = true
			node.remove_meta('reference')
			references_update.emit()

func _on_references_update() -> void:
	_clear_copy_nodes()
	_create_anchors()

func _clear_copy_nodes() -> void:
	for _node in _copy_nodes:
		_node.queue_free()
	_copy_nodes = []

func _create_anchors() -> void:
	while(_anchors.size() > repeat_count):
		_anchors.pop_back().queue_free()
	
	while(_anchors.size() < repeat_count):
		var anchor: Node3D = Node3D.new()
		anchor.set_meta('anchor', true)
		add_child(anchor)
		_anchors.append(anchor)
		
	if _reference_nodes.size() > 0:
		for i in range(_anchors.size()):
			slide_process(i)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_distance_scrolled += delta * scroll_speed * (Global.scroll_speed if !Engine.is_editor_hint() else 1)
	#_distance_scrolled = scroll_speed
	var max_vector: Vector3 = (repeat_vector * repeat_count)
	if max_vector.length() > 0 && visible:
		for i in range(_anchors.size()):
			var object: Node3D = _anchors[i]
			var _position: Vector3 = i * repeat_vector + repeat_vector.normalized() * _distance_scrolled

			var div: float = fmod(_position.length(), max_vector.length()) / max_vector.length()
			var is_positive: bool = _position.normalized().dot(repeat_vector.normalized()) >= 0
			_position = (div if is_positive else 1 - div) * max_vector
			if _position.length() - (repeat_vector.normalized() * scroll_speed * delta).length() < 0:
				slide_process(i)
		
			object.position = _position
		
func slide_process(anchor_index) -> void:
	if prop_chance == 1 || randf() < prop_chance:
		if !oneshot:
			refresh_object(anchor_index)
		else:
			_has_oneshot = true
			refresh_object(anchor_index, _has_oneshot)

func refresh_object(anchor_index: int, no_attach: bool = false) -> void:
	if _reference_nodes.size() > 0:
		var anchor: Node3D = _anchors[anchor_index]
		var ref_index: int = _get_random_reference_index()
		var found_copy_index: int = _copy_nodes.find_custom(func(item: Node3D): return item.get_meta('copy_of', 0) == ref_index && !item.has_meta('used_by'))
		var new_node: Node3D
		if found_copy_index == -1:
			new_node = create_target_copy(ref_index)
		else:
			new_node = _copy_nodes[found_copy_index]
		
		if anchor.get_child_count() > 0:
			_detach_from_anchor(anchor.get_child(0))
		if !no_attach:
			attach_to_anchor(new_node, anchor_index)

func _detach_from_anchor(node: Node3D) -> void:
	if node:
		node.visible = false
		_anchors[node.get_meta('used_by')].remove_child(node)
		node.remove_meta('used_by')
	
func attach_to_anchor(node: Node3D, anchor_index: int) -> void:
	if oneshot && _has_oneshot:
		return
	
	node.visible = true
	node.set_meta('used_by', anchor_index)
	_anchors[anchor_index].add_child(node)
	node.position = Vector3.ZERO

func create_target_copy(reference_index: int) -> Node3D:
	var reference_node = _reference_nodes[reference_index]
	var node: Node3D = reference_node.duplicate()
	node.set_meta('copy_of', reference_index)
	_copy_nodes.append(node)
	node.visible = true
	
	return node

func _get_random_reference_index() -> int:
	return randi_range(0, _reference_nodes.size() - 1)
