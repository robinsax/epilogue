shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;

#include "res://meta/util.gdshaderinc"
#include "res://environment/desert/desert_base.gdshaderinc"
#include "res://assets/foliage_impactors.gdshaderinc"
#include "res://assets/lighting.gdshaderinc"

uniform sampler2D biomes;
uniform vec2 terrain_offset;
uniform float terrain_size;

varying vec3 vert_world_pos;
varying vec2 vert_world_uv;

void vertex() {
	vert_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vert_world_uv = (vert_world_pos.xz - terrain_offset) / terrain_size;

	float wind = desert_wind(vert_world_pos) * 0.2;
	VERTEX += (vec3(0.0, 0.0, wind * 4.0) * UV.x) - vec3(0.0, 0.05, 0.0);

	vec4 world_impact = get_world_impactor_data(vert_world_pos, 1.5);
	vec3 effect = normalize(world_impact.xyz) * world_impact.a * 0.2;
	effect.y = -world_impact.a * 0.2;
	VERTEX += effect;
}

void fragment() {
	vec4 biome_sample = texture(biomes, vert_world_uv);
	vec2 noise_sample_point = downsample_point(abs(UV - vec2(0.5)) + vec2(vert_world_pos.x, vert_world_pos.z), 20.0);
	float noise_sample = perlin(noise_sample_point * 10.0);
	if (noise_sample > 0.5 - (abs(UV.x - 0.5) * 0.5) + (UV.y * 0.2)) {
		discard;
	}

	ALBEDO = (vec3(0.5, 0.48, 0.3) * 0.15);
	ALBEDO -= (vec3(0.05) * perlin(downsample_point(vert_world_pos.xy, 10.0) * 2.0));
	METALLIC = 1.0;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	if (view_modifier == 1) {
		ALBEDO = vec3(max(ALBEDO.r, ALBEDO.b));
	}
}
