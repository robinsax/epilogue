shader_type spatial;

#include "res://environment/desert/desert_base.gdshaderinc"

uniform sampler2D heights;
uniform sampler2D biomes;
uniform sampler2D paths;

varying flat vec2 vert_world_uv;
varying vec3 world_pos;
varying float vert_slope;

void vertex() {
	// Called for every vertex the material is visible on.
	vert_world_uv = UV;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vert_slope = 1.0 - world_normal.y;
}

void fragment() {
	vec4 height_sample = texture(heights, vert_world_uv);

	vec4 biome_sample = texture(biomes, vert_world_uv);
	vec4 base = desert_color(biome_sample) * 0.45;

	ALBEDO = base.rgb + vec3(height_sample.r * vert_slope);
	METALLIC = base.a;

	vec4 path_sample = texture(paths, downsample_point(UV, 200.0));
	float max_path = max(path_sample.r, max(path_sample.g, path_sample.b));

	if (max_path > 0.4 && biome_sample.g < 0.01) {
		ALBEDO += vec3(1.0) * perlin(downsample_point(world_pos.xz, 2.0)) * 0.1;
		ALBEDO += vec3(0.1);
	}

	// Detail effects.
	if (biome_sample.r < 0.3 && biome_sample.g < 0.01) {
		vec2 detail_sample = downsample_point(world_pos.xz, 2.0);
		detail_sample = vec2(detail_sample.x, detail_sample.y * 0.6);
		ALBEDO -= vec3(1.0) * perlin(detail_sample) * 0.05;
	}
	else if (biome_sample.r > 0.3 && biome_sample.g < 0.01) {
		vec2 detail_sample = downsample_point(world_pos.xz, 10.0);
		ALBEDO -= vec3(1.0, 0.9, 1.0) * perlin(detail_sample * 6.0) * ((biome_sample.r - 0.3) / 0.7) * 0.1;
	}
	else {
		vec2 detail_sample = downsample_point(world_pos.xz, 5.0);
		ALBEDO -= vec3(1.0) * perlin(detail_sample) * biome_sample.g * 0.05;
	}
}
