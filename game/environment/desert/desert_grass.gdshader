shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;

#include "res://environment/desert/desert_base.gdshaderinc"
#include "res://environment/foliage/foliage_impactors.gdshaderinc"

uniform sampler2D biomes;
uniform vec2 terrain_offset;
uniform float terrain_size;

varying vec2 vert_world_uv;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vert_world_uv = (world_pos.xz - terrain_offset) / terrain_size;

	float vertical = (1.0 - UV.y);
	VERTEX += vec3(desert_wind(world_pos) * vertical, 0.0, 0.0);

	vec3 nearest_impactor = get_nearest_world_impactor(world_pos);
	float nearest_impactor_dist = length(nearest_impactor - world_pos);
	if (nearest_impactor_dist < 1.0) {
		float weight = 1.0 - nearest_impactor_dist;
		vec3 delta = world_pos - nearest_impactor;
		delta.y = 0.0;
		vec3 effect = normalize(delta) * weight * 0.5;
		effect.y = -weight * 0.7;
		VERTEX += effect;
	}
}

void fragment() {
	vec4 biome_sample = texture(biomes, vert_world_uv);
	float uv_sample = floor(UV.y * 6.0) / 6.0;
	ALBEDO = (desert_color(biome_sample).rgb - vec3(uv_sample * 0.4)) * 0.2;
	ALBEDO += vec3(0.0, 0.3, 0.1) * 0.05;

	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
