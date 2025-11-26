shader_type spatial;

#include "res://meta/util.gdshaderinc"
#include "res://assets/lighting.gdshaderinc"

uniform vec3 base_color : source_color;
uniform float tatter;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	VERTEX += vec3(perlin(world_pos.xz + (TIME * 0.4)) - 0.5) * 0.04;
}

void fragment() {
	float noise_a = perlin(downsample_point(world_pos.xz + (vec2(world_pos.y, 0.0) * 0.2), 40.0) * 10.0);
	if (noise_a < tatter) discard;

	ALBEDO = base_color + vec3(noise_a * 0.02);
	if (view_modifier == 1) ALBEDO = vec3(0.5);
}
