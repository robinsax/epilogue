shader_type spatial;

#include "res://meta/util.gdshaderinc"
#include "res://assets/lighting.gdshaderinc"

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (perlin(downsample_point(UV * 20.0, 2)) < 0.5) ALPHA = 0.3;

	ALBEDO = vec3(0.3);
	if (view_modifier == 1) {
		EMISSION = vec3(0.2);
	}
}
