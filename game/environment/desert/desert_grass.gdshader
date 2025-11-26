shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;

#include "res://environment/desert/desert_base.gdshaderinc"
#include "res://assets/foliage_impactors.gdshaderinc"
#include "res://assets/lighting.gdshaderinc"

uniform sampler2D biomes;
uniform vec2 terrain_offset;
uniform float terrain_size;

varying vec2 vert_world_uv;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vert_world_uv = (world_pos.xz - terrain_offset) / terrain_size;

	float vertical = (1.0 - UV.y);
	VERTEX += vec3(desert_wind(world_pos) * vertical, 0.0, 0.0);

	vec4 world_impact = get_world_impactor_data(world_pos, 1.5);
	vec3 effect = normalize(world_impact.xyz) * world_impact.a * 0.5;
	effect.y = -world_impact.a * 0.7;
	VERTEX += effect;
}

void fragment() {
	vec4 biome_sample = texture(biomes, vert_world_uv);
	float uv_sample = floor(UV.y * 6.0) / 6.0;
	ALBEDO = (desert_color(biome_sample).rgb - vec3(uv_sample * 0.4)) * 0.2;
	ALBEDO += vec3(0.0, 0.3, 0.1) * 0.02;

	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	if (view_modifier == 1) {
		ALBEDO = vec3(max(ALBEDO.r, ALBEDO.b));
	}
}
