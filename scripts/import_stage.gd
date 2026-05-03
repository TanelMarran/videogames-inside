@tool
extends EditorScenePostImport

static var material_map: Dictionary:
	get():
		return {
				'viena_landscape': "res://materials/viena_landscape.tres",
				'dutch_landscape': "res://materials/dutch_landscape.tres"
			}

func _post_import(scene):
	var save_path: String = RegEx.create_from_string('res://(\\w+/)+').search(get_source_file()).get_string()
	var reg_match: RegExMatch = RegEx.create_from_string('(\\w*).glb').search(get_source_file())
	if reg_match:
		var root_node: Node3D = Node3D.new()
		root_node.name = 'Root'
		walk_node(root_node, scene, root_node)
		var saved_scene: PackedScene = PackedScene.new()
		saved_scene.pack(root_node)
		ResourceSaver.save(saved_scene, save_path + '_import_scn_%s.tscn' % [reg_match.strings[1]])
		# iterate(scene, save_path + 'import/')
	return scene

var excluded = ['stage', 'scene_collection']

func walk_node(target_node: Node3D, current_node: Node3D, resource_owner_node: Node3D) -> void:
	var node_name = current_node.name.to_lower().replace(' ', '_')
	var is_excluded = node_name in excluded
	var ownerless_nodes: Array[Node3D] = []
	var child
	if !is_excluded:
		if current_node is MeshInstance3D:
			child = Looper.new()
			var mesh_instance: MeshInstance3D = current_node.duplicate()
			var mesh: Mesh = mesh_instance.mesh
			var blender_material_name: String = mesh.surface_get_material(0).resource_name
			var godot_material: Material = load(material_map.get(blender_material_name)) if material_map.has(blender_material_name) else null
			if godot_material:
				mesh.surface_set_material(0, godot_material)
			child.add_child(mesh_instance)
			mesh_instance.name = 'mesh_' + current_node.name
			ownerless_nodes.append(mesh_instance)
		elif current_node is Node3D:
			child = Node3D.new()
		target_node.add_child(child)
		child.name = current_node.name
		child.owner = resource_owner_node
		for ownerless_node in ownerless_nodes:
			ownerless_node.owner = resource_owner_node
	
	for grandchild in current_node.get_children():
		walk_node(target_node if is_excluded else child, grandchild, resource_owner_node)

func iterate(node: Node3D, save_path: String):
	var node_name = node.name.to_lower().replace(' ', '_')
	var is_excluded = node_name in excluded
	print('Iterating: %s' % node_name)
	if node is MeshInstance3D:
		print('- Type: MeshInstance3D')
		var mesh: Mesh = node.mesh
		var blender_material_name: String = mesh.surface_get_material(0).resource_name
		print('- Found material: %s' % blender_material_name)
		var godot_material: Material = load(material_map.get(blender_material_name)) if material_map.has(blender_material_name) else null
		if godot_material:
			mesh.surface_set_material(0, godot_material)
		var save_filename = save_path + node_name + '.res';
		print('- Saving to path: %s' % save_path)
		DirAccess.make_dir_recursive_absolute(save_path)
		ResourceSaver.save(mesh, save_filename)
		print('- Saved %s to: %s' % [node_name, save_filename])
	elif node is Node3D:
		print('- Type: Node3D')
		for child in node.get_children():
			iterate(child, save_path + ('' if is_excluded else node_name + '/'))
