shader_type spatial;

#include "desert_base.gdshaderinc"

uniform sampler2D heights;
uniform sampler2D biomes;

varying vec2 vert_world_uv;
varying float vert_slope;

void vertex() {
	// Called for every vertex the material is visible on.
	vert_world_uv = UV;

	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vert_slope = 1.0 - world_normal.y;
}

void fragment() {
	vec4 height_sample = texture(heights, vert_world_uv);

	vec4 base = desert_base(biomes, vert_world_uv);
	ALBEDO = base.rgb + vec3(height_sample.r * vert_slope);
	METALLIC = base.a;
}
