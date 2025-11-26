global uniform sampler2D world_foliage_impactors;

vec3[24] get_world_impactors() {
	vec3[24] output;

	for (int i = 0; i < 24; i++) {
		output[i] = texelFetch(world_foliage_impactors, ivec2(i, 0), 0).rgb;
	}

	return output;
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

vec4 get_world_impactor_data(vec3 world_pos, float radius) {
	vec3 nearest = get_nearest_world_impactor(world_pos);
	vec3 delta = nearest - world_pos;
	float dist = length(delta);
	delta.y = 0.0;

	float weight = 0.0;
	if (dist < radius) weight = radius - dist;

	return vec4(delta, weight);
}