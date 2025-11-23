#include "res://meta/util.gdshaderinc"

const vec3 base_color = vec3(0.5, 0.4, 0.2);
const vec3 greenery_color = vec3(0.28, 0.28, 0.1);
const vec3 cliffs_color  = vec3(0.7, 0.5, 0.3);

// Alpha channel is metallic.
vec4 desert_color(vec4 biome_sample) {
	float greens = biome_sample.r;
	float cliffs = biome_sample.g;

	float metallic = 0.0;

	if (greens < 0.0 || cliffs > 0.0) {
		greens = 0.0;
		metallic = 1.0;
	}

	// Minor elevation shade.
	vec3 albedo = (
		mix(
			// Greens mix.
			mix(base_color, greenery_color, greens),
			// Cliffs mix.
			cliffs_color, cliffs
		)
	);

	return vec4(albedo, metallic);
}

float desert_wind(vec3 world_pos) {
	return perlin(world_pos.xz * TIME * 0.001) * 0.5;
}