shader_type spatial;

#include "res://meta/util.gdshaderinc"

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//if (perlin(UV) < 0.5) discard;

	ALBEDO = vec3(UV.x, UV.y, 0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
