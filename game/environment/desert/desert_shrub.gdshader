shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;

#include "res://meta/util.gdshaderinc"
#include "res://environment/desert/desert_base.gdshaderinc"
#include "res://environment/foliage/foliage_impactors.gdshaderinc"

uniform sampler2D biomes;
uniform vec2 terrain_offset;
uniform float terrain_size;

varying vec3 vert_world_pos;
varying vec2 vert_world_uv;

void vertex() {
	vert_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vert_world_uv = (vert_world_pos.xz - terrain_offset) / terrain_size;

	float wind = desert_wind(vert_world_pos);
	VERTEX += (vec3(0.0, 0.0, wind * 4.0) * UV.x) + vec3(0.0, 0.05, 0.0);
	vec3 nearest_impactor = get_nearest_world_impactor(vert_world_pos);
	float nearest_impactor_dist = length(nearest_impactor - vert_world_pos);
	if (nearest_impactor_dist < 1.0) {
		float weight = 1.0 - nearest_impactor_dist;
		VERTEX.y += -weight * 0.7;
	}
}

void fragment() {
	vec4 biome_sample = texture(biomes, vert_world_uv);
	vec2 noise_sample_point = downsample_point(abs(UV - vec2(0.5)) + vec2(vert_world_pos.x, vert_world_pos.z), 20.0);
	float noise_sample = perlin(noise_sample_point * 10.0);
	if (noise_sample > 0.5) {
		discard;
	}

	ALBEDO = (vec3(0.5, 0.51, 0.4) * 0.6) - vec3(0.2);
	ALBEDO -= (vec3(0.03) * perlin(downsample_point(vert_world_pos.xy, 10.0) * 2.0));
	METALLIC = 1.0;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
