@tool
extends EditorScenePostImport

static var material_map: Dictionary:
	get():
		if !material_map:
			material_map = {
				'viena_landscape': "res://scenes/materials/viena_landscape.tres",
				'dutch_landscape': "res://scenes/materials/dutch_landscape.tres"
			}
		return material_map

func _post_import(scene):
	var save_path: String = RegEx.create_from_string('res://(\\w+/)+').search(get_source_file()).get_string()
	var reg_match: RegExMatch = RegEx.create_from_string('(\\w*).glb').search(get_source_file())
	if reg_match:
		iterate(scene, save_path + 'import/')
	return scene

var excluded = ['stage', 'scene_collection']

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
