shader_type spatial;

#include "res://assets/lighting.gdshaderinc"

uniform vec3 base_color : source_color;
uniform float thermal_emit;
uniform vec3 emissive : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = base_color;
	EMISSION = emissive;
	if (view_modifier == 1) {
		ALBEDO = vec3(0.5) + thermal_emit;
		EMISSION = vec3(thermal_emit);
	}
}
