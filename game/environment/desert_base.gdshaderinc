const vec3 base_color = vec3(0.99, 0.95, 0.8);
const vec3 greenery_color = vec3(0.6, 0.7, 0.25);
const vec3 cliffs_color  = vec3(0.7, 0.5, 0.3);

// Alpha channel is metallic.
vec4 desert_base(sampler2D biomes_sampler, vec2 uv) {
	vec4 biome_sample = texture(biomes_sampler, uv);
	float greens = biome_sample.r;
	float cliffs = biome_sample.g;

	float metallic = 0.0;

	if (greens < 0.3 || cliffs > 0.0) {
		greens = 0.0;
		metallic = 1.0;
	}
	else {
		greens = min(1.0, greens * 2.0);
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