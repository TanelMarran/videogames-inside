shader_type spatial;
render_mode unshaded, world_vertex_coords;

uniform vec3 u_color: source_color;
uniform float snap_size = .5;
uniform float time_scale = 1.0;
uniform vec3 splice_direction = vec3(0.0, 0.0, 1.0);
uniform vec3 movement_direction = vec3(0.0, 0.0, 1.0);
uniform float movement_strength = 1.0;

void vertex() {
	vec3 offset = TIME * time_scale * vec3(1.0, 0.0, 0.0);
	float _movement_strength = max(max(0, dot(movement_direction, -NORMAL)), dot(splice_direction, NORMAL)) * movement_strength;
	vec3 speed_offset = -movement_direction * _movement_strength;
	VERTEX = floor(((VERTEX + offset) / vec3(snap_size / 10.0))) * vec3(snap_size / 10.0) - offset + speed_offset;
}

void fragment() {
	ALBEDO = u_color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
