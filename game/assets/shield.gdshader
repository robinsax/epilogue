shader_type spatial;
render_mode cull_disabled;

#include "res://meta/util.gdshaderinc"

global uniform int view_modifier;

uniform vec3 base_color : source_color;
uniform float alpha_scale;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	bool rand_sample = perlin(vec2(UV.x, TIME * 0.01) * 40.0) < 0.5;
	ALBEDO = base_color;
	EMISSION = base_color;
	if (rand_sample) ALPHA = 0.5;
	ALPHA *= alpha_scale;

	if (view_modifier == 1) {
		ALBEDO = vec3(-0.2);
		EMISSION = vec3(-0.1);
		if (rand_sample) EMISSION = vec3(-1.0);
		ALPHA = 0.8;
	}
}
