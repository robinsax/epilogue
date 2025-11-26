shader_type spatial;
render_mode cull_disabled;

global uniform int view_modifier;

#include "res://meta/util.gdshaderinc"

void vertex() {
	float noise_a = perlin(vec2(TIME, VERTEX.x));
	float noise_b = perlin(vec2(TIME, VERTEX.y));
	VERTEX += vec3(noise_a * UV.x, (noise_b - 0.5) * UV.x, 0.0);
}

void fragment() {
	float noise_a = perlin(downsample_point(UV, 10.0) + vec2(TIME, 0.0));
	if (abs(UV.y - 0.5) + abs(UV.x - 0.5) > noise_a * 0.7) discard;

	float noise_b = perlin(downsample_point(UV, 10.0) + vec2(TIME));
	ALBEDO = (vec3(0.5, 0.2, 0.1) * 0.5) + (vec3(0.4, 0.4, 0.0) * noise_b * 0.1);
	if (view_modifier == 1) ALBEDO = vec3(1.0);

	EMISSION = ALBEDO;
	METALLIC = 1.0;
	SPECULAR = 0.0;
	RADIANCE = vec4(0.3);
}
