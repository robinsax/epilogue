instance uniform vec3 world_impactor_0;
instance uniform vec3 world_impactor_1;
instance uniform vec3 world_impactor_2;
instance uniform vec3 world_impactor_3;
instance uniform vec3 world_impactor_4;
instance uniform vec3 world_impactor_5;
instance uniform vec3 world_impactor_6;
instance uniform vec3 world_impactor_7;

vec3[8] get_world_impactors() {
	return vec3[](
		world_impactor_0,
		world_impactor_1,
		world_impactor_2,
		world_impactor_3,
		world_impactor_4,
		world_impactor_5,
		world_impactor_6,
		world_impactor_7
	);
}

vec3 get_nearest_world_impactor(vec3 world_pos) {
	vec3 nearest_impactor = vec3(0.0);
	float nearest_dist = 1000.0;
	vec3[] world_impactors = get_world_impactors();
	for (int i = 0; i < world_impactors.length(); i++) {
		if (length(world_impactors[i]) < 0.01) continue;

		float dist = length(world_impactors[i] - world_pos);
		if (dist < nearest_dist) {
			nearest_dist = dist;
			nearest_impactor = world_impactors[i];
		}
	}

	return nearest_impactor;
}